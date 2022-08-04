#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# system files #
str_file1="/etc/default/grub"
str_file2="/etc/initramfs-tools/modules"
str_file3="/etc/modules"
str_file4="/etc/modprobe.d/pci-blacklists.conf"
str_file5="/etc/modprobe.d/vfio.conf"

# system file backups #
str_oldFile1=$(pwd)"/etc_default_grub.old"
str_oldFile2=$(pwd)"/etc_initramfs-tools_modules.old"
str_oldFile3=$(pwd)"/etc_modules"

# debug logfiles #
str_logFile0=`find . -name *hugepages*log*`
str_logFile1=`find . -name etc_default_grub.log`
str_logFile2=`find . -name etc_initramfs-tools_modules.log`
str_logFile3=`find . -name etc_modules.log`
str_logFile4=`find . -name etc_modprobe.d_pci-blacklists.conf.log`
str_logFile5=`find . -name etc_modprobe.d_vfio.conf.log`
str_logFile6=`find . -name grub-menu.log`

# prompt #
echo -en "$0: Uninstalling VFIO setup... "

# clear logfiles #
if [[ ! -z $str_logFile0 ]]; then rm $str_logFile0; fi
if [[ ! -z $str_logFile1 ]]; then rm $str_logFile1; fi
if [[ ! -z $str_logFile2 ]]; then rm $str_logFile2; fi
if [[ ! -z $str_logFile3 ]]; then rm $str_logFile3; fi
if [[ ! -z $str_logFile4 ]]; then rm $str_logFile4; fi
if [[ ! -z $str_logFile5 ]]; then rm $str_logFile5; fi
if [[ ! -z $str_logFile6 ]]; then rm $str_logFile6; fi

## 1 ##     # /etc/default/grub
if [[ ! -e $str_oldFile1 ]]; then
    mv $str_file1 $str_oldFile1

    # find GRUB line and comment out #
    while read -r str_line1; do

        # match line #
        if [[ $str_line1 == *"GRUB_CMDLINE_LINUX_DEFAULT"* && $str_line1 != "#GRUB_CMDLINE_LINUX_DEFAULT"* ]]; then
            str_line1="#"$str_line1             # update line
        fi

        echo -e $str_line1  >> $str_file1       # append to new file

    done < $str_oldFile1

    echo -e "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" >> $str_file1
else
    cp $str_oldFile1 $str_file1
fi
    
rm $str_oldFile1

## 2 ##     # initramfs-tools
bool_readLine=true

if [[ ! -e $str_oldFile2 ]]; then
    mv $str_file2 $str_oldFile2

    while read -r str_line1; do
        if [[ $str_line1 == *"# START #"* || $str_line1 == *"portellam/VFIO-setup"* ]]; then
            bool_readLine=false
        fi

        if [[ $bool_readLine == true ]]; then
            echo -e $str_line1 >> $str_file2
        fi

        if [[ $str_line1 == *"# END #"* ]]; then
            bool_readLine=true
        fi
    done < $str_oldFile2
else
    cp $str_oldFile2 $str_file2
fi

rm $str_oldFile2

## 3 ##     # /etc/modules
bool_readLine=true

if [[ ! -e $str_oldFile3 ]]; then
    mv $str_file3 $str_oldFile3

    while read -r str_line1; do
        if [[ $str_line1 == *"# START #"* || $str_line1 == *"portellam/VFIO-setup"* ]]; then
            bool_readLine=false
        fi

        if [[ $bool_readLine == true ]]; then
            echo -e $str_line1 >> $str_file3
        fi

        if [[ $str_line1 == *"# END #"* ]]; then
            bool_readLine=true
        fi
    done < $str_oldFile3
else
    cp $str_oldFile3 $str_file3
fi

rm $str_oldFile3

## 4 ##     # /etc/modprobe.d/pci-blacklist.conf
if [[ ! -z $str_file4 ]]; then rm $str_file4; fi

## 5 ##     # /etc/modprobe.d/vfio.conf
if [[ ! -z $str_file5 ]]; then rm $str_file5; fi

echo -e " Complete.\n"
sudo update-grub                    # update GRUB
sudo update-initramfs -u -k all     # update INITRAMFS
IFS=$SAVEIFS                        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0