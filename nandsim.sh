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
        echo -e "\e[32m[+] $TOOL_INSTALL successfully installed/configured\e[0m" | tee -a $SCRIPT_DIR/nandsim.log;
     else
        echo -e "\e[31m[-] ERROR: $TOOL_INSTALL not installed/configured correctly\e[0m" | tee -a $SCRIPT_DIR/nandsim.log;
        exit 1;
    fi
    sudo echo > /dev/null 2>&1;
}

create_nandsim() {
    TOOL_INSTALL="modprobe nandsim";
    sudo modprobe nandsim first_id_byte=$1 second_id_byte=$2 third_id_byte=$3 fourth_id_byte=$4;
    check_status_install;

    NANDSIM_STATUS=$(cat /proc/mtd);
    if [[ $NANDSIM_STATUS ]]; then
        echo -e "\e[32mSuccess: $NANDSIM_STATUS\e[0m"
    else
        echo -e "\e[31mKernel module not correctly installed. Exiting\e[0m"
        exit 1;
    fi
}

copy_image_mtd() {
    TOOL_INSTALL="dd image to mtdblock0";
    sudo dd if=$5 of=/dev/mtdblock0;
    check_status_install;
}

attach_mount() {
    TOOL_INSTALL="ubiattach";
    sudo ubiattach /dev/ubi_ctrl -m 0
    check_status_install;

    TOOL_INSTALL="mount to /mnt/ubifs";
    sudo mkdir /mnt/ubifs
    sudo mount -t ubifs ubi0_0 /mnt/ubifs
    check_status_install;
}


##############################################################################################################################
main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        
    if [ "$#" -lt 5 ]; then
        echo -e "\e[31m[-] ERROR: Missing required arguments (expected 5, got $#).\e[0m\n"
        usage;
    fi
    create_nandsim;
    copy_image_mtd;
    attach_mount;
    echo -e "\e[31mCopy the files you want from /mnt/ubifs to a separate location for further perusal.\e[0m"
    echo -e "\e[31mThen run the ubi-clean.sh script.\e[0m"
}

main;

exit 0;