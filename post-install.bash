#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# parse and execute functions #
str_input1=$1

echo -e "$0: Executing functions... "
str_dir1="post-install-functions"
declare -a arr_dir1=`ls $str_dir1`

# call functions #
for str_line1 in $arr_dir1; do

    # execute sh/bash scripts in directory
    if [[ $str_line1 == *".bash" ]]; then sudo bash $str_dir1"/"$str_line1 $str_input1 $bool_isVFIOsetup; fi  
    
    if [[ $str_line1 == *".sh" ]]; then sudo sh $str_dir1"/"$str_line1 $str_input1 $bool_isVFIOsetup; fi
    #

done

# NOTE: disclaimer here

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo -e "$0: Executing functions... Complete."
exit 0