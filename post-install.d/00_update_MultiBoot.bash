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

    if [[ `echo ${str_pwd##*/}` != "post-install.d" ]]; then
        if [[ -e `find . -name post-install.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name post-install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

echo -en "$0: Updating Multi-boot setup... "

## parameters ##
    str_rootKernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`      # latest kernel
    str_rootKernel=${str_rootKernel: 1}

# input files #
    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

    str_inFile6=`find . -name *etc_grub.d_proxifiedScripts_custom`
    str_logFile6=`find . -name *custom_grub.log*`

# system files #
    str_outFile6="/etc/grub.d/proxifiedScripts/custom"

# system file backups #
    str_oldFile7=$str_outFile6".old"

## /etc/grub.d/proxifiedScripts/custom ##
    str_orig1='#$str_rootKernel#'
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
                str_line1="${str_line1/"$str_orig1"/"$str_rootKernel"}"
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
