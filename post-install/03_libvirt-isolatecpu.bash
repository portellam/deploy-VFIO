#!/bin/bash sh

exit 0  # DEBUG

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# parameters #
str_inFile1=`find . -name *libvirt-isolatecpu_hook*`
str_outFile1="/etc/libvirt/hooks/qemu"
str_inFile2=`find . -name *libvirt-nosleep@.service*`
str_outFile2="/etc/systemd/system/libvirt-nosleep@.service"

if [[ -e $str_inFile1 && -e $str_inFile2 ]]; then
    touch $str_outFile1 $str_outFile2

    # write to file #
    read -r str_line; do
        echo $str_line >> $str_outFile1
    done < $str_inFile1

    # write to file #
    read -r str_line; do
        echo $str_line >> $str_outFile2
    done < $str_inFile2
else
    echo -e "$0: libvirt-nosleep: File(s) missing. Skipping."
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0