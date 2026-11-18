#!/bin/bash

usage() {
echo -e "\e[33mUsage:\e[0m $0 <first_id_byte> <second_id_byte> <third_id_byte> <fourth_id_byte> <image_file>"
echo ""
echo "Arguments:"
echo "  first_id_byte   : 1st NAND ID byte in hex (e.g., 0x2c)"
echo "  second_id_byte  : 2nd NAND ID byte in hex (e.g., 0xda)"
echo "  third_id_byte   : 3rd NAND ID byte in hex (e.g., 0x90)"
echo "  fourth_id_byte  : 4th NAND ID byte in hex (e.g., 0x95)"
echo "  image_file      : Path to the UBIFS image file to mount"
echo ""
echo -e "\e[36mExample:\e[0m $0 0x2c 0xda 0x90 0x95 firmware.ubi"
exit 1
}

check_status_install() {
    if [ "$?" == 0 ]; then
        echo -e "\e[32m[+] $TOOL_INSTALL successfully installed/configured\e[0m";
     else
        echo -e "\e[31m[-] ERROR: $TOOL_INSTALL not installed/configured correctly\e[0m";
        exit 1;
    fi
    sudo echo > /dev/null 2>&1;
}

ubi_kernel() {
    # Kernel module mtdblock
    sudo modprobe mtdblock;
    MTD_STATUS=$(lsmod | grep -Ei 'mtd')
    if [[ $MTD_STATUS ]]; then
        echo -e "\e[32mKernel module \e[35mmtdblock\e[32m successfully installed.\e[0m"
    else
        echo -e "\e[31mKernel modules \e[35mmtdblock\e[31m could not be installed.\e[0m"
        exit 1;
    fi

    # Kernel module ubi
    sudo modprobe ubi;
    UBI_STATUS=$(lsmod | grep 'ubi')
    if [[ $UBI_STATUS ]]; then
        echo -e "\e[32mKernel module \e[35mubi\e[32m successfully installed.\e[0m"
    else
        echo -e "\e[31mKernel module \e[35mubi\e[31m could not be installed.\e[0m"
        exit 1;
    fi

    # Kernel module ubifs
    sudo modprobe ubifs;
    UBI_STATUS=$(lsmod | grep 'ubifs')
    if [[ $UBI_STATUS ]]; then
        echo -e "\e[32mKernel module \e[35mubifs\e[32m successfully installed.\e[0m"
    else
        echo -e "\e[31mKernel module \e[35mubifs\e[31m could not be installed.\e[0m"
        exit 1;
    fi

    echo -e "\e[32mNecessary kernel modules successfully installed now running nandsim\e[0m"
}

create_nandsim() {
    TOOL_INSTALL="modprobe nandsim";
    sudo modprobe nandsim first_id_byte=$first_id_byte second_id_byte=$second_id_byte third_id_byte=$third_id_byte fourth_id_byte=$fourth_id_byte;
    check_status_install;
    sync;
    sleep 1;
    NANDSIM_STATUS=$(cat /proc/mtd);
    if [[ $NANDSIM_STATUS ]]; then
        echo -e "\e[32mSuccess:\n $NANDSIM_STATUS\e[0m"
    else
        echo -e "\e[31mKernel module not correctly installed. Exiting\e[0m"
        exit 1;
    fi
}

copy_image_mtd() {
    TOOL_INSTALL="dd image to mtdblock0";
    echo -e "\e[32mWriting image \e[35m$image_file\e[32m to /dev/mtdblock0\e[0m"
    sudo dd if=$image_file of=/dev/mtdblock0;
    check_status_install;
}

attach_mount() {
    TOOL_INSTALL="ubiattach";
    sudo ubiattach /dev/ubi_ctrl -m 0
    check_status_install;

    TOOL_INSTALL="mount to /mnt/ubifs";
    if [ -e /mnt/ubifs ]; then
        echo -e "\e[32m /mnt/ubifs exists, reusing\e[0m"
    else
        sudo mkdir /mnt/ubifs;
    fi
    sudo mount -t ubifs ubi0_0 /mnt/ubifs
    check_status_install;
}

##############################################################################################################################
main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo -e "\e[35m[*] Sudo password needed"
    echo -e "$(sudo echo)\e[0m"
    
    if [ -e /dev/ubi_ctrl ]; then
        echo -e "\e[32mUBI kernel Modules already installed."
    else
        ubi_kernel;
    fi
    echo -e "\e[35m";
    read -p "Please be aware that the next steps may overwrite an existing mtdblock0. Do you really want to continue (y/n)" DO_IT;
    printf -v DO_IT_NOW "%.1s" "${DO_IT^^}"
    echo -e "\e[0m";
    if [ "$DO_IT_NOW" == "Y" ]; then
        create_nandsim;
        copy_image_mtd;
        attach_mount;
    else
        exit 0;       
    fi
    
    echo -e "\e[32m=========================================================================================="
    echo -e "\e[32mCopy the files you want from /mnt/ubifs to a separate location for further perusal."
    echo -e "\e[32mThen run the ubi-clean.sh script."
    echo -e "==========================================================================================\e[0m"
}

# Check if all command line parameters are provided, otherwise show usage
if [ $# -ne 5  ]; then
        echo -e "\e[31m[-] ERROR: Missing required arguments (expected 5, got $#).\e[0m\n"
        usage;
else
    first_id_byte=$1;
    second_id_byte=$2;
    third_id_byte=$3;
    fourth_id_byte=$4;
    image_file=$5;
    # Run main module calling relevant functions
    main;
    exit 0
fi

exit 0;