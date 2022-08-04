#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# parameters #
declare -i int_count=0      # reset counter

# system files #
#str_file1="/etc/default/zramswap"
str_file2="/etc/default/zram-swap"

# system file backups #
str_oldFile2=$(pwd)"/etc_default_zram-swap.old"

# prompt #
echo -en "$0: Uninstalling ZRAM-swap setup... "

## 2 ##     # /etc/default/zram-swap
bool_readLine=true

# if [[ -z $str_oldFile2 && -e $str_file2 ]]; then
#     mv $str_file2 $str_oldFile2

#     while read -r str_line1; do
#         if [[ $str_line1 == *"# START #"* || $str_line1 == *"portellam/VFIO-setup"* ]]; then
#             bool_readLine=false
#         fi

#         if [[ $bool_readLine == true ]]; then
#             echo -e $str_line1 >> $str_file2
#         fi

#         if [[ $str_line1 == *"# END #"* ]]; then
#             bool_readLine=true
#         fi
#     done < $str_oldFile2
# else
#     cp $str_oldFile2 $str_file2
# fi
    
# rm $str_oldFile2

if [[ -e $str_file2 ]]; then rm $str_file2; fi
if [[ -e $str_oldFile2 ]]; then rm $str_oldFile2; fi

echo -e "Complete.\n"
sudo systemctl stop zram-swap zramswap
sudo systemctl disable zram-swap zramswap
IFS=$SAVEIFS                                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0