#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $0'\n\tor\n\t'su' and 'bash $0'.\n$0: Exiting."
        exit 0
    fi

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "uninstall.d" ]]; then
        if [[ -e `find . -name uninstall.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name uninstall.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# system files #
    str_outFile1="/etc/grub.d/proxifiedScripts/custom"

# file check #
    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

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