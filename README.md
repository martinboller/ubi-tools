# UBIFS / NAND & NOR Flash Extraction Helper Scripts

A collection of lightweight Bash scripts designed to streamline the process of emulating **NAND** (`nandsim`) or **NOR** (`mtdram`) flash devices in Linux, writing a UBI/UBIFS firmware image to the simulated MTD device, and mounting the filesystem for extraction and analysis.

## Prerequisites

* A Linux environment with kernel headers/modules for `mtdblock`, `ubi`, `ubifs`, `nandsim` (for NAND), and `mtdram` (for NOR).
* `mtd-utils` installed (provides `ubiattach` and `ubidetach`).
* `sudo` privileges (required to load/unload kernel modules, write to `/dev/mtdblock0`, and mount filesystems).

## Repository Contents

* **`ubi-nandsim.sh`**: Loads required kernel modules, initializes a simulated **NAND** flash device using 4 chip ID bytes, writes the target firmware image to `/dev/mtdblock0`, attaches the UBI device, and mounts it to `/mnt/ubifs`.
* **`ubi-norsim.sh`**: Loads required kernel modules, initializes a simulated **NOR** flash device in RAM based on the erase block size (PEB) and image size, writes the firmware image to `/dev/mtdblock0`, attaches the UBI device, and mounts it to `/mnt/ubifs`.
* **`ubi-clean.sh`**: Unmounts `/mnt/ubifs`, detaches the UBI device, and unloads all related kernel modules (`nandsim`, `nandcore`, `mtdram`, `ubifs`, `ubi`, and `mtdblock`) to restore the system state.
* **`ubi-kernel.sh`**: Standalone helper script that loads the `mtdblock` and `ubifs` kernel modules and verifies they are active.

## Usage Workflow

### 1. Make Scripts Executable
```bash
chmod +x ubi-nandsim.sh ubi-norsim.sh ubi-clean.sh ubi-kernel.sh
```

### 2. Simulate Flash and Mount the Image

Choose **Option A** for a NAND flash dump or **Option B** for a NOR flash dump. Both scripts will automatically load the necessary kernel modules (`mtdblock`, `ubi`, `ubifs`) if they are not already active.

#### Option A: NAND Flash (`ubi-nandsim.sh`)
Run `ubi-nandsim.sh` by passing the 4 NAND ID bytes (in hex) that match your target flash chip's geometry (page size, block size, total size), followed by the path to your firmware image:
```bash
./ubi-nandsim.sh <first_id_byte> <second_id_byte> <third_id_byte> <fourth_id_byte> <path_to_ubi_image>
```
**Example:**
```bash
./ubi-nandsim.sh 0x20 0xac 0x00 0x15 firmware.img
```
*(Note: You can look up the specific 4-byte ID values for your flash chip in the Linux kernel's `nand_ids.c` source file).*

#### Option B: NOR Flash (`ubi-norsim.sh`)
Run `ubi-norsim.sh` by passing the NOR flash erase block size (PEB) in KiB (commonly `64`, `128`, or `256`), followed by the path to your firmware image. The script automatically calculates and allocates the required total RAM size:
```bash
./ubi-norsim.sh <erase_size_kib> <path_to_ubi_image>
```
**Example:**
```bash
./ubi-norsim.sh 64 firmware-nor.ubi
```
*(Tip: To find the PEB size of an unknown UBI dump, check the byte offset between `UBI#` headers using `grep -abo "UBI#" firmware-nor.ubi | head -n 5` and divide the spacing by `1024`).*

### 3. Extract Files & Cleanup
Once mounted, the extracted filesystem will be accessible at `/mnt/ubifs`. Copy any desired files to a separate working directory, then run the cleanup script to safely unmount the volume and unload the kernel modules:
```bash
./ubi-clean.sh
```
## Raw UBIFS vs. Full UBI Image
Both ubi-nandsim.sh and ubi-norsim.sh expect a full UBI image (containing UBI EC/VID headers, starting with UBI#). If you extracted a standalone UBIFS volume image (starting with magic 0x06101831, i.e., 31 18 10 06 in little-endian), ubiattach will fail unless it the MTD device isn't formatted (ubiformat /dev/mtd0), a volume created (ubimkvol), and the volume written with ubiupdatevol /dev/ubi0_0 image.ubifs. The scripts now handle that scenario as well.

## Disclaimer
These scripts execute commands with `sudo` and write directly to `/dev/mtdblock0`. Ensure no physical MTD devices are currently attached to `/dev/mtdblock0` before running `ubi-nandsim.sh` or `ubi-norsim.sh` to avoid unintended data loss. (I have stories to tell).

## License

This project is open-source software licensed under the **[European Union Public Licence (EUPL)](https://interoperable-europe.ec.europa.eu/licence/european-union-public-licence-version-12-eupl)** (v1.2 or later). 

By contributing or using this repository, you agree to be bound by the terms of the EUPL. You may obtain a copy of the License at:

* [Official EUPL Text & Translations](https://interoperable-europe.ec.europa.eu/collection/eupl/eupl-text-eupl-12)