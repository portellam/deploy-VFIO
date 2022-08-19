#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# system files #
str_outFile1="/etc/grub.d/proxifiedScripts/custom"

# input files #
str_inFile1=`find . -name *etc_grub.d_proxifiedScripts_custom`

if [[ -e $str_inFile1 ]]; then
    cp $str_inFile1 $str_outFile1       # copy from template
else
    echo -e "Failed. File(s) missing:"

    if [[ -z $str_inFile1 ]]; then 
        echo -e "\t'$str_inFile1'"
    fi
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0