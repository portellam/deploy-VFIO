#!/usr/bin/env bash

#
# Original author: Alex Portell <github.com/portellam>
#
# function updates logfile with latest kernel, outputs to system file
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

echo -en "$0: Updating Multi-boot setup... "

## parameters ##
str_root_Kernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`      # latest kernel
str_root_Kernel=${str_root_Kernel: 1}

# input files #
str_inFile6=`find . -name *etc_grub.d_proxifiedScripts_custom`
str_logFile6=`find . -name *custom_grub.log*`

# system files #
str_outFile6="/etc/grub.d/proxifiedScripts/custom"

# system file backups #
str_oldFile7=$str_outFile6".old"

## /etc/grub.d/proxifiedScripts/custom ##
str_orig1='#$str_root_Kernel#'
str_prefix=""

if [[ -e $str_inFile6 && -e $str_logFile6 ]]; then
    if [[ -e $str_outFile6 ]]; then
        mv $str_outFile6 $str_oldFile7      # create backup
    fi

    cp $str_inFile6 $str_outFile6           # copy over blank

    # write to tempfile #
    echo >> $str_outFile6
    echo >> $str_outFile6
    while read -r str_line1; do
        if [[ $str_line1 == *"}"* ]]; then
            str_prefix=""
        fi

        # update kernel #
        if [[ $str_line1 == *$str_orig1* ]]; then
            str_line1="${str_line1/"$str_orig1"/"$str_root_Kernel"}"
        fi

        echo -e $str_prefix$str_line1 >> $str_outFile6

        if [[ $str_line1 == *"{"* ]]; then
            str_prefix+="\t"
        fi  
    done < $str_logFile6                    # read from template
else
    bool_missingFiles=true
fi

if [[ $bool_missingFiles == true ]]; then
    echo -e "Failed.\n$0: File(s) missing:"
            
    if [[ -z $str_logFile6 ]]; then 
        echo -e "\t'$str_logFile6'"
    fi   
else
    chmod 755 $str_outFile6 $str_oldFile6   # set proper permissions
    echo -e "Complete."
    sudo update-grub
fi

exit 0
