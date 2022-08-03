#!/bin/bash sh

# TO-DO:
# -create simple GUI popup or app for functions.

# function steps #
# 1. parse list of active virtual machines.
# 2. ask user to dompmwakeup given virtual machine(s).
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
str_input1=""

# user input method, Y/n three times before fail #
function UserInput {
    declare -i int_count=0            # reset counter
    echo $str_input1
    while true; do
        # passthru input variable if it is valid #
        if [[ $1 == "Y"* || $1 == "y"* ]]; then
            str_input1=$1     # input variable
            break
        fi
        #
        # manual prompt #
        if [[ $int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                     # default input     # NOTE: change here
        else                                        # manual prompt
            echo -en "$0: [Y/n]: "
            read str_input1
            # string to upper
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            #
        fi
        #
        case $str_input1 in
            "Y"|"N")
                break
            ;;
            *)
                echo -e "$0: Invalid input."
            ;;
        esac  
        ((int_count++))   # counter
    done  
}
#

# wakeup sleeping VM #
declare -a arr_virsh_name_notOff=`sudo virsh list --name`
declare -a arr_virsh_all_pmsuspend=`sudo virsh list --all | grep pmsuspended`
bool_input1=false

for str_line1 in $arr_virsh_name_notOff; do
    for str_line2 in $arr_virsh_all_pmsuspend; do
        if [[ $str_line2 == *$str_line1* ]]; then
            bool_input1=true
            echo -en "$0: Wakeup suspended virtual machine '$str_line1'? [Y/n]: "
            read str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            UserInput $str_input1
            if [[ $str_input1 == "Y" ]]; then
                sudo virsh dompmwakeup $str_line1
            fi
        fi
    done
done
#

IFS=$SAVEIFS        # reset IFS
if [[ $bool_input1 == false ]]; then
    echo -en "$0: No suspended virtual machines found. "
fi

echo "Exiting."
exit 0