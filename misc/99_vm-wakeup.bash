#!/bin/bash sh

# create simple GUI popup or app to resume VMs
# create another for sleeping or hibernating (no hybrid) VMs (VMs must have qemu guest additions installed)
#sudo virsh dompmsuspend --target mem --domain WIN10_GAME_VM_Q35_UEFI_6c2t_24G_GPU1

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

local_str_input1=""

# user input method, Y/n three times before fail #
function UserInput {
    declare -i local_int_count=0            # reset counter
    echo $local_str_input1
    while true; do
        # passthru input variable if it is valid #
        if [[ $1 == "Y"* || $1 == "y"* ]]; then
            local_str_input1=$1     # input variable
            break
        fi
        #
        # manual prompt #
        if [[ $local_int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts."
            local_str_input1="N"                     # default input     # NOTE: change here
        else                                        # manual prompt
            echo -en "$0: [Y/n]: "
            read local_str_input1
            # string to upper
            local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
            local_str_input1=${local_str_input1:0:1}
            #
        fi
        #
        case $local_str_input1 in
            "Y"|"N")
                break
            ;;
            *)
                echo -e "$0: Invalid input."
            ;;
        esac  
        ((local_int_count++))   # counter
    done  
}
#

# wakeup sleeping VM #
declare -a arr_virsh_name_notOff=`sudo virsh list --name`
declare -a arr_virsh_all_pmsuspend=`sudo virsh list --all | grep pmsuspended`
local_bool_input1=false

for local_str_line1 in $arr_virsh_name_notOff; do
    for local_str_line2 in $arr_virsh_all_pmsuspend; do
        if [[ $local_str_line2 == *$local_str_line1* ]]; then
            local_bool_input1=true
            echo -en "$0: Wakeup suspended virtual machine '$local_str_line1'? [Y/n]: "
            read local_str_input1
            local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
            UserInput $local_str_input1
            if [[ $local_str_input1 == "Y" ]]; then
                sudo virsh dompmwakeup $local_str_line1
            fi
        fi
    done
done
#

IFS=$SAVEIFS        # reset IFS
if [[ $local_bool_input1 == true ]]; then echo "$0: Exiting."
else echo "$0: No suspended virtual machines found. Exiting."; fi
exit 0