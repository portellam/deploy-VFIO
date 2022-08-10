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
str_repo="portellam/Auto-Xorg"
str_repoName=`echo $str_repo | cut -d '/' -f2`
str_userName=`echo $str_repo | cut -d '/' -f1`
cd /root

if [[ ! `find -wholename *$str_repo*` ]]; then
    mkdir /root/git /root/git/$str_userName
    cd /root/git/$str_userName
    git clone https://www.github.com/$str_repo
else
    cd /root/git/$str_userName
fi

if [[ ! -z "/root/git/$str_repo" ]]; then
    cd /root/git/$str_repo
    bash ./installer.sh
    echo -e "\n$0: Executing... Complete."
else
    echo -e "\n$0: Executing... Failed."
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
