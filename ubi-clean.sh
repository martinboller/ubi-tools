#!/bin/bash

check_status_install() {
    if [ "$?" == 0 ]; then
        echo -e "\e[32m[+] $TOOL_INSTALL successfully installed/configured\e[0m";
     else
        echo -e "\e[31m[-] ERROR: $TOOL_INSTALL not installed/configured correctly\e[0m";
        #exit 1;
    fi
    sudo echo > /dev/null 2>&1;
}

cleanup() {
    # Unmount
    TOOL_INSTALL="unmount";
    sudo umount /mnt/ubifs
    check_status_install;

    # Detach ubi
    TOOL_INSTALL="ubidetach";
    sudo ubidetach -m 0

    # remove nandsim and nandcore kernel modules
    TOOL_INSTALL="remove nandsim kernel module";
    sudo modprobe -r nandsim;
    check_status_install;

    TOOL_INSTALL="remove nandcore kernel module";
    sudo modprobe -r nandcore;
    check_status_install;

    # Remove ubi and mtdblock kernel modules
    TOOL_INSTALL="remove ubifs kernel module";
    sudo modprobe -r ubifs;
    check_status_install;

    TOOL_INSTALL="remove mtdblock kernel module";
    sudo modprobe -r mtdblock;
    check_status_install;

    TOOL_INSTALL="remove mtd kernel module";
    sudo modprobe -r mtd;
    check_status_install;

    # Double checking that everything is removed
    MODPROBE_STATUS=$(lsmod | grep -E "ubi|mtd|nand")
    if [[ $MODPROBE_STATUS ]]; then
        echo -e "\e[31mKernel modules could not be removed.\e[0m"
    else
        echo -e "\e[32mKernel modules successfully removed.\e[0m"
    fi
}

##############################################################################################################################
main() {

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
    cleanup;

}

main;

exit 0;
