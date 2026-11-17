#!/bin/bash
# Kernel module mtdblock
sudo modprobe mtdblock;
MTD_STATUS=$(lsmod | grep -Ei 'mtd')
if [[ $MTD_STATUS ]]; then
    echo -e "\e[32mKernel module \e[35mmtdblock\e[32m successfully installed.\e[0m"
else
    echo -e "\e[31mKernel modules \e[35mmtdblock\e[31m could not be installed.\e[0m"
    exit 1;
fi

# Kernel module ubifs
sudo modprobe ubifs;
UBI_STATUS=$(lsmod | grep -Ei 'ubi')
if [[ $UBI_STATUS ]]; then
    echo -e "\e[32mKernel module \e[35mubifs\e[32m successfully installed.\e[0m"
else
    echo -e "\e[31mKernel module \e[35mubifs\e[31m could not be installed.\e[0m"
    exit 1;
fi

echo -e "\e[32mNecessary kernel modules successfully installed, please run nandsim.sh\e[0m"
exit 0