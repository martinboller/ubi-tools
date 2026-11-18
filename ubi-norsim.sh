#!/bin/bash

usage() {
    echo -e "\e[33mUsage:\e[0m $0 <erase_size_kib> <image_file>"
    echo ""
    echo "Arguments:"
    echo "  erase_size_kib  : NOR flash erase block size (PEB) in KiB (e.g., 64, 128, 256)"
    echo "  image_file      : Path to the UBI/UBIFS image file to mount"
    echo ""
    echo -e "\e[36mExample:\e[0m $0 64 firmware-nor.ubi"
    exit 1
}

check_status_install() {
    if [ "$?" == 0 ]; then
        echo -e "\e[32m[+] $TOOL_INSTALL successfully installed/configured\e[0m"
    else
        echo -e "\e[31m[-] ERROR: $TOOL_INSTALL not installed/configured correctly\e[0m"
        exit 1
    fi
    sudo echo > /dev/null 2>&1
}

ubi_kernel() {
    for mod in mtdblock ubi ubifs; do
        sudo modprobe "$mod"
        if lsmod | grep -qw "$mod"; then
            echo -e "\e[32mKernel module \e[35m$mod\e[32m successfully installed.\e[0m"
        else
            echo -e "\e[31mKernel module \e[35m$mod\e[31m could not be installed.\e[0m"
            exit 1
        fi
    done
    echo -e "\e[32mNecessary kernel modules successfully installed; configuring mtdram...\e[0m"
}

create_mtdram() {
    if [ ! -f "$image_file" ]; then
        echo -e "\e[31m[-] ERROR: Image file '$image_file' not found.\e[0m"
        exit 1
    fi

    # Calculate image size in bytes and round up to a multiple of erase_size
    local img_bytes
    img_bytes=$(stat -c%s "$image_file")
    local erase_bytes=$((erase_size_kib * 1024))
    local blocks=$(( (img_bytes + erase_bytes - 1) / erase_bytes ))
    local total_size_kib=$(( blocks * erase_size_kib ))

    echo -e "\e[36m[*] Image size: ${img_bytes} bytes -> Allocating ${total_size_kib} KiB (${blocks} PEBs of ${erase_size_kib} KiB)\e[0m"

    TOOL_INSTALL="modprobe mtdram"
    sudo modprobe mtdram total_size="$total_size_kib" erase_size="$erase_size_kib"
    check_status_install
    sync
    sleep 1

    MTDRAM_STATUS=$(cat /proc/mtd)
    if [[ $MTDRAM_STATUS ]]; then
        echo -e "\e[32mSuccess:\n$MTDRAM_STATUS\e[0m"
    else
        echo -e "\e[31mKernel module not correctly installed. Exiting.\e[0m"
        exit 1
    fi
}

copy_image_mtd() {
    TOOL_INSTALL="dd image to mtdblock0"
    echo -e "\e[32mWriting image \e[35m$image_file\e[32m to /dev/mtdblock0\e[0m"
    sudo dd if="$image_file" of=/dev/mtdblock0 bs="${erase_size_kib}k"
    check_status_install
}

attach_mount() {
    TOOL_INSTALL="ubiattach"
    sudo ubiattach /dev/ubi_ctrl -m 0
    check_status_install

    TOOL_INSTALL="mount to /mnt/ubifs"
    if [ -e /mnt/ubifs ]; then
        echo -e "\e[32m/mnt/ubifs exists, reusing\e[0m"
    else
        sudo mkdir -p /mnt/ubifs
    fi
    sudo mount -t ubifs ubi0_0 /mnt/ubifs
    check_status_install
}

main() {
    echo -e "\e[35m[*] Sudo password needed\e[0m"
    sudo -v

    if [ -e /dev/ubi_ctrl ]; then
        echo -e "\e[32mUBI kernel modules already installed.\e[0m"
    else
        ubi_kernel
    fi

    echo -e "\e[35m"
    read -p "Please be aware that the next steps may overwrite an existing mtdblock0. Do you really want to continue (y/n) " DO_IT
    printf -v DO_IT_NOW "%.1s" "${DO_IT^^}"
    echo -e "\e[0m"

    if [ "$DO_IT_NOW" == "Y" ]; then
        create_mtdram
        copy_image_mtd
        attach_mount
    else
        exit 0
    fi

    echo -e "\e[32m=========================================================================================="
    echo -e "Copy the files you want from /mnt/ubifs to a separate location for further perusal."
    echo -e "Then run ubi-clean.sh to clean up after the script."
    echo -e "==========================================================================================\e[0m"
}

if [ $# -ne 2 ]; then
    echo -e "\e[31m[-] ERROR: Missing or extra arguments (expected 2, got $#).\e[0m\n"
    usage
else
    erase_size_kib=$1
    image_file=$2
    main
    exit 0
fi