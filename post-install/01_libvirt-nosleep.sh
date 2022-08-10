#!/usr/bin/env bash

#
# Original author: Alex Portell <github.com/portellam>
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

echo -en "$0: Executing... "

# parameters #
str_inFile1=`find . -name *libvirt-nosleep_hook*`
str_outFile1="/etc/libvirt/hooks/qemu"
str_inFile2=`find . -name *libvirt-nosleep@.service*`
str_outFile2="/etc/systemd/system/libvirt-nosleep@.service"

if [[ -e $str_inFile1 && -e $str_inFile2 ]]; then
    touch $str_outFile1 $str_outFile2

    # write to file #
    while read -r str_line1; do
        echo $str_line1 >> $str_outFile1
    done < $str_inFile1

    # write to file #
    while read -r str_line1; do
        echo $str_line1 >> $str_outFile2
    done < $str_inFile2

    echo -e "Complete."
else
    echo -e "Failed. File(s) missing:"

    if [[ -z $str_inFile1 ]]; then 
        echo -e "\t'$str_inFile1'"
    fi

    if [[ -z $str_inFile2 ]]; then 
        echo -e "\t'$str_inFile2'"
    fi
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0