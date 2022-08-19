#!/bin/bash sh

# function steps #
# 1. check if it repo exists, continue.
# 2. install
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

echo -e "$0: Executing...\n"

# parameters #
str_gitRepo="portellam/Auto-Xorg"
str_gitUserName=`echo $str_gitRepo | cut -d '/' -f1`
mkdir ./git

# clone repo #
if [[ ! `find -wholename *./git/$str_gitRepo*` ]]; then
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
