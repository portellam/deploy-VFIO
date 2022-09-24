#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
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

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
        str_input1=${str_input1:0:1}
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!

            else
                echo -en "\t$1 [Y/n]: "
                read str_input1

                str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
                str_input1=${str_input1:0:1}
            fi

            case $str_input1 in
                "Y"|"N")
                    break;;

                *)
                    echo -en "\tInvalid input. ";;
            esac

            ((int_count++))         # increment counter
        done
    }

# check if virtualization is supported
    function CheckIOMMU
    {
        if [[ -z $(compgen -G "/sys/kernel/iommu_groups/*/devices/*") ]]; then
            echo "WARNING: Virtualization (AMD IOMMU or Intel VT-D) is NOT enabled or available in the BIOS/UEFI.\nExiting."
            exit 1

        else
            echo "Virtualization is enabled in the BIOS/UEFI. Continuing..."
        fi
    }

# main #
    # parse and execute functions #

    # parameters #
    str_dir1="post_install.d"

    # call functions #
    CheckIfUserIsRoot
    CheckIOMMU

    if [[ -e $(find .. -name *$str_dir1*) ]]; then
        echo -e "Executing functions..."

        declare -a arr_dir1=$(ls $str_dir1)

        # call functions #
        for str_line1 in $arr_dir1; do

            # update parameters #
            str_input1=""

            # execute sh/bash scripts in directory
            if [[ ( $str_line1 == *".bash" || $str_line1 == *".sh" ) && $str_line1 != *".log" ]]; then
                ReadInput "Execute '$str_line1'?"
                echo
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".bash" && $str_line1 != *".log" ]]; then
                bash $str_dir1"/"$str_line1
                echo
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
                sh $str_dir1"/"$str_line1
                echo
            fi
        done

        echo -en "Review changes made. "

    else
        echo -en "FAILURE: Missing files. "
    fi

    IFS=$SAVEIFS        # reset IFS
    echo "Exiting."
    exit 0