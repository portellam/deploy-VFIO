#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
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

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

echo -en "$0: Executing... "

# parameters #
    str_outDir1="/etc/systemd/system/"
    str_outFile1="audio-loopback-user.service"

    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

    str_inFile1=`find . -name *audio-loopback-user.service*`

# file check #
    if [[ -e $str_inFile1 ]]; then
        cp -r $str_inFile1 $str_outDir1$str_outFile1
        chmod +x $str_outDir1$str_outFile1
        echo -e "Complete.\n$0: To finish, execute as User (not Root):\n\tsystemctl --user daemon-reload\n\tsystemctl enable $str_outFile1\n\tsystemctl start $str_outFile1"
    else
        echo -e "Failed. File(s) missing:"
        echo -e "\t$str_inFile1"
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0