#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1. check if it repo exists, continue.
# 2. install
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_file1=$(echo ${0##/*})
            str_file1=$(echo $str_file1 | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'. Exiting."
            exit 1
        fi
    }

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    echo -e "Executing...\n"

# parameters #
    str_gitRepo="portellam/Auto-Xorg"
    str_gitUserName=$(echo $str_gitRepo | cut -d '/' -f1)
    mkdir ./git

# clone repo #
    if [[ ! $(find -wholename *./git/$str_gitRepo*) ]]; then
        mkdir ./git/$str_gitUserName
        git clone https://www.github.com/$str_gitRepo ./git/$str_gitRepo
    fi

# execute repo #
    if [[ ! -z "./git/$str_gitRepo" ]]; then
        cd ./git/$str_gitRepo
        sudo bash ./installer.bash
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0