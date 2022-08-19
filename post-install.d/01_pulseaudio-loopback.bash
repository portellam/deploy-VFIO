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

echo -en "$0: Executing... "

# parameters #
    str_outDir1="/etc/systemd/system/"
    str_outFile1="audio-loopback-user.service"
    str_inFile1=`find .. -name *audio-loopback-user.service*`

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