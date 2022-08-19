#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# precede with echo prompt for input #
# ask user for input then validate #
    function ReadInput {
        echo -en "$0: "

        if [[ $str_input1 == "Y" ]]; then
            echo -en $str_output1$str_input1
        else
            declare -i int_count=0      # reset counter

            while true; do
                # manual prompt #
                if [[ $int_count -ge 3 ]]; then       # auto answer
                    echo "Exceeded max attempts."
                    str_input1="N"                    # default input     # NOTE: change here
                else
                    echo -en $str_output1
                    read str_input1

                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                    str_input1=${str_input1:0:1}
                fi

                case $str_input1 in
                    "Y"|"N")
                        break;;
                    *)
                        echo -en "$0: Invalid input. ";;
                esac

                ((int_count++))         # increment counter
            done
        fi
    }

# parse and execute functions #
    str_output1=""
    str_dir1="post-install.d"

    if [[ -z `find . -name $str_dir1*` ]]; then
        echo -e "$0: Executing functions... Failed. Missing files."
    else
        echo -e "$0: Executing functions..."

        declare -a arr_dir1=`ls $str_dir1 | sort -h`
        # call functions #
        for str_line1 in $arr_dir1; do

            # input variable auto executes functions #
            if [[ `echo $1 | tr '[:lower:]' '[:upper:]'` == "Y"* ]]; then
                str_input1="Y"
            else
                str_input1=""
            fi

            # execute sh/bash scripts in directory
            if [[ $str_line1 == *".bash"||*".sh" && $str_line1 != *".log" ]]; then
                str_output1="Execute '$str_line1'? [Y/n]: "
                ReadInput $str_input1
                echo
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".bash" && $str_line1 != *".log" ]]; then
                sudo bash $str_dir1"/"$str_line1
                echo
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
                sudo sh $str_dir1"/"$str_line1
                echo
            fi
        done

        echo -e "$0: Review changes made. Exiting."
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
