#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

## user input ##
str_input1=""

# precede with echo prompt for input #
# ask user for input then validate #
function ReadInput {
    if [[ -z $str_input1 ]]; then read str_input1; fi

    str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
    str_input1=${str_input1:0:1}
    ValidInput $str_input1
}

# validate input, ask again, default answer NO #
function ValidInput {
    declare -i int_count=0    # reset counter
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
            str_input1="N"                    # default input     # NOTE: change here
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
##

# check if system supports IOMMU #
if [[ ! compgen -G "/sys/kernel/iommu_groups/*/devices/*" > /dev/null ]]; then
    echo "$0: WARNING: Virtualization (AMD IOMMU or Intel VT-D) is NOT enabled or available in the BIOS/UEFI.\n$0: VFIO setup will continue, enable/review availability after execution."
fi
#

# parse and execute functions #
bool_isVFIOsetup=false          # a canary to check for previous VFIO setup installation
str_input1=$1

echo -en "$0: PLEASE READ: Automatically answer Yes/No prompts with 'Yes'? [Y/n]: "
ReadInput $str_input1

echo -e "$0: Executing sudo functions."
str_dir1="sudo-functions"
declare -a arr_dir1=`ls $str_dir1`

# call functions #
while [[ $bool_isVFIOsetup == false ]]; do

    for str_line1 in $arr_dir1; do

        # execute sh/bash scripts in directory
        if [[ $str_line1 == *".sh"||*".bash" ]]; then
            echo -en "\n$0: Execute '$str_line1'? [Y/n]: "
            UserInput_1 $str_input1
            echo -e "\n$0: Executing '$str_line1'."
        fi

        if [[ $str_input1 =="Y" && $str_line1 == *".bash" ]]; then sudo bash $str_dir1"/"$str_line1 $str_input1 $bool_isVFIOsetup; fi  
    
        if [[ $str_input1 =="Y" && $str_line1 == *".sh" ]]; then sudo sh $str_dir1"/"$str_line1 $str_input1 $bool_isVFIOsetup; fi  
        #

    done
    #

    echo -e "$0: DISCLAIMER: Please review changes made.\n\tIf a given network (Ethernet, WLAN) or storage controller (NVME, SATA) is necessary for the Host machine, and the given device is passed-through, the Host machine will lose access to it."
done
#

IFS=$SAVEIFS        # reset IFS
echo "$0: Exiting."
exit 0