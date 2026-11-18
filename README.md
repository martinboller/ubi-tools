# UBIFS / NANDSim Extraction Helper Scripts

A collection of lightweight Bash scripts designed to streamline the process of emulating a NAND flash device using Linux's `nandsim` kernel module, writing a UBIFS firmware image to it, and mounting the filesystem for extraction and analysis.

## Prerequisites

* A Linux environment with kernel headers/modules for `mtdblock`, `ubifs`, and `nandsim`.
* `mtd-utils` installed (provides `ubiattach` and `ubidetach`).
* `sudo` privileges (required to load/unload kernel modules, write to `/dev/mtdblock0`, and mount filesystems).

## Repository Contents

* **`ubi-nandsim.sh`**: Initializes the simulated NAND flash device with specific chip ID bytes, writes the target firmware image to `/dev/mtdblock0`, attaches the UBI device, and mounts it to `/mnt/ubifs`.
* **`ubi-clean.sh`**: Unmounts `/mnt/ubifs`, detaches the UBI device, and unloads all related kernel modules (`nandsim`, `nandcore`, `ubifs`, `ubifs`, and `mtdblock`) to restore the system state.
* **`ubi-kernel.sh`**: Loads the required `mtdblock` and `ubifs` kernel modules and verifies they are active (and nothing else)

## Usage Workflow

### 1. Make Scripts Executable
```bash
chmod +x ubi-kernel.sh nandsim.sh ubi-clean.sh
```

### 2. Load Kernel Modules, Simulate NAND and Mount the Image
Run `ubi-nandsim.sh` by passing the 4 NAND ID bytes (in hex) that match your target flash chip's geometry (page size, block size, total size), followed by the path to your firmware image:
```bash
./ubi-nandsim.sh <first_id_byte> <second_id_byte> <third_id_byte> <fourth_id_byte> <path_to_ubifs_image>
```
**Example:**
```bash
./ubi-nandsim.sh 0x20 0xac 0x00 0x15 firmware.img
```
*(Note: You can look up the specific 4-byte ID values for your flash chip in the Linux kernel's `nand_ids.c` source file).*

Once mounted, the extracted filesystem will be accessible at `/mnt/ubifs`. I recommend copying any desired files to a separate working directory, then [cleaning up](#3-cleanup).

### 3. Cleanup
After extracting your files, run the cleanup script to safely unmount the volume and unload the kernel modules:
```bash
./ubi-clean.sh
```

## Disclaimer
These scripts execute commands with `sudo` and write directly to `/dev/mtdblock0`. Ensure no physical MTD devices are currently attached to `/dev/mtdblock0` before running `ubi-nandsim.sh` to avoid unintended data loss.