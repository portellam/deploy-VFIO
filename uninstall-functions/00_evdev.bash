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
str_file1="/etc/libvirt/qemu.conf"

# system file backups #
str_oldFile1=$(pwd)"/etc_libvirt_qemu.conf.old"

# prompt #
echo -en "$0: Uninstalling Evdev setup... "

## 1 ##     # /etc/libvirt/qemu.conf
bool_readLine=true

if [[ -z $str_oldFile1 ]]; then
    mv $str_file1 $str_oldFile1

    while read -r str_line1; do
        if [[ $str_line1 == *"# START #"* || $str_line1 == *"portellam/VFIO-setup"* ]]; then
            bool_readLine=false
        fi

        if [[ $bool_readLine == true ]]; then
            echo -e $str_line1 >> $str_file1
        fi

        if [[ $str_line1 == *"# END #"* ]]; then
            bool_readLine=true
        fi
    done < $str_oldFile1
else
    cp $str_oldFile1 $str_file1
fi
    
rm $str_oldFile1

echo -e " Complete.\n"
systemctl enable libvirtd
systemctl restart libvirtd
IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0