#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1. parse cpu info.
# 2. ask user to setup Static CPU isolation
# 3. save output to log for GRUB, to be used for either Static or Multi-boot VFIO
#
# NOTES:
# - parse will save up to two cores (and threads) for host
# - see post-installation, libvirt-hooks for 'Dynamic' CPU isolation
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
        declare -i int_count=0

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

            ((int_count++))
        done
    }

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# debug logfiles #
    readonly str_thisFile="${0##*/}"
    readonly str_logFile1="$str_thisFile.log"

# main function #
    function ParseCPU
    {
        # parameters #
            readonly arr_coresByThread=($(cat /proc/cpuinfo | grep 'core id' | cut -d ':' -f2 | cut -d ' ' -f2))
            readonly int_totalCores=$(cat /proc/cpuinfo | grep 'cpu cores' | uniq | cut -d ':' -f2 | cut -d ' ' -f2)
            readonly int_totalThreads=$(cat /proc/cpuinfo | grep 'siblings' | uniq | cut -d ':' -f2 | cut -d ' ' -f2)
            readonly int_multiThread=$(( $int_totalThreads / $int_totalCores ))
            declare -a arr_totalCores=()
            declare -a arr_hostCores=()
            declare -a arr_hostThreads=()
            declare -a arr_hostThreadSets=()
            # declare -a arr_virtCores=()
            declare -a arr_virtThreadSets=()
            declare -i int_hostCores=1          # default value

        # reserve remainder cores to host #
            # >= 4-core CPU, leave max 2
            if [[ $int_totalCores -ge 4 ]]; then
                readonly int_hostCores=2

            # 2 or 3-core CPU, leave max 1
            elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then
                readonly int_hostCores=1

            # 1-core CPU, do not reserve cores to virt
            else
                readonly int_hostCores=$int_totalCores
            fi

        # group threads for host #
            for (( int_i=0 ; int_i<$int_multiThread ; int_i++ )); do
                declare -i int_firstHostCore=$int_hostCores
                declare -i int_firstHostThread=$((int_hostCores+int_totalCores*int_i))
                declare -i int_lastHostCore=$((int_totalCores-1))
                declare -i int_lastHostThread=$((int_lastHostCore+int_totalCores*int_i))
                str_virtThreads+="${int_firstHostThread}-${int_lastHostThread},"
            done

            # update parameters #
            if [[ ${str_virtThreads: -1} == "," ]]; then
                str_virtThreads=${str_virtThreads::-1}
            fi

        # group threads by core id #
            for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do
                str_line1=""
                declare -i int_thisCore=${arr_coresByThread[int_i]}

                for (( int_j=0 ; int_j<$int_multiThread ; int_j++ )); do
                    int_thisThread=$((int_thisCore+int_totalCores*int_j))
                    str_line1+="$int_thisThread,"

                    if [[ $int_thisCore -lt $int_hostCores ]]; then
                        arr_hostThreads+=("$int_thisThread")
                    fi
                done

                # update parameters #
                if [[ ${str_line1: -1} == "," ]]; then
                    str_line1=${str_line1::-1}
                fi

                arr_totalThreads+=("$str_line1")

                # save output for cpu isolation (host) #
                if [[ $int_thisCore -lt $int_hostCores ]]; then
                    arr_hostCores+=("$int_thisCore")
                    arr_hostThreadSets+=("$str_line1")

                # save output for cpuset/cpumask (qemu cpu pinning) #
                else
                    # arr_virtCores+=("$int_thisCore")
                    arr_virtThreadSets+=("$str_line1")
                fi
            done

        # update parameters #
            readonly arr_totalThreads
            readonly arr_hostCores
            readonly arr_hostThreadSets
            readonly arr_virtThreadSets

        # save output to string for cpuset and cpumask #
            #
            # example:
            #
            # host 0-1,8-9
            #
            # virt 2-7,10-15
            #
            #
            # cores     bit masks       mask
            # 0-7       0b11111111      FF      # total cores
            # 0,4       0b00010001      11      # host cores
            #
            # 0-11      0b111111111111  FFF     # total cores
            # 0-1,6-7   0b000011000011  C3      # host cores
            #
            # find cpu mask #
            readonly int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))
            declare -i int_hostThreads_mask=0

            for int_thisThread in ${arr_hostThreads[@]}; do
                int_hostThreads_mask+=$(( 2 ** $int_thisThread ))
            done

            readonly int_hostThreads_mask

            # int to hex #
            readonly hex_totalThreads_mask=$(printf '%x\n' $int_totalThreads_mask)
            readonly hex_hostThreads_mask=$(printf '%x\n' $int_hostThreads_mask)

        # debug prompt #
            function DebugOutput
            {
                echo -e "$0: ========== DEBUG PROMPT ==========\n"

                echo -e "$0: "'${#arr_coresByThread[@]}\t= '"'${#arr_coresByThread[@]}'"
                echo -e "$0: "'${#arr_totalThreads[@]}\t= '"'${#arr_totalThreads[@]}'"
                echo -e "$0: "'$int_totalCores\t\t= '"'$int_totalCores'"
                echo -e "$0: "'$int_totalThreads\t\t= '"'$int_totalThreads'"
                echo -e "$0: "'$hex_totalThreads_mask\t= '"'$hex_totalThreads_mask'"
                echo -e "$0: "'$int_hostCores\t\t= '"'$int_hostCores'"
                echo -e "$0: "'${#arr_hostThreads[@]}\t= '"'${#arr_hostThreads[@]}'"
                echo -e "$0: "'${#arr_hostThreadSets[@]}\t= '"'${#arr_hostThreadSets[@]}'"
                echo -e "$0: "'$hex_hostThreads_mask\t= '"'$hex_hostThreads_mask'"
                echo -e "$0: "'$str_virtThreads\t= '"'$str_virtThreads'"
                echo -e "$0: "'$int_multiThread\t\t= '"'$int_multiThread'"
                echo -e "$0: "'${#arr_virtThreadSets[@]}\t= '"'${#arr_virtThreadSets[@]}'"

                for (( i=0 ; i<${#arr_coresByThread[@]} ; i++ )); do echo -e "$0: '$""{arr_coresByThread[$i]}'\t= '${arr_coresByThread[$i]}'"; done && echo
                for (( i=0 ; i<${#arr_totalThreads[@]} ; i++ )); do echo -e "$0: '$""{arr_totalThreads[$i]}'\t= '${arr_totalThreads[$i]}'"; done && echo
                for (( i=0 ; i<${#arr_hostThreads[@]} ; i++ )); do echo -e "$0: '$""{arr_hostThreads[$i]}'\t= '${arr_hostThreads[$i]}'"; done && echo
                for (( i=0 ; i<${#arr_hostThreadSets[@]} ; i++ )); do echo -e "$0: '$""{arr_hostThreadSets[$i]}'\t= '${arr_hostThreadSets[$i]}'"; done && echo
                for (( i=0 ; i<${#arr_virtThreadSets[@]} ; i++ )); do echo -e "$0: '$""{arr_virtThreadSets[$i]}'\t= '${arr_virtThreadSets[$i]}'"; done && echo

                echo -e "\n$0: ========== DEBUG PROMPT =========="
                exit 0
            }

            # DebugOutput     # uncomment to debug here

        # clear existing file #
            if [[ -e $str_logFile1 ]]; then
                rm $str_logFile1
            fi

        # write to file #
            str_line1=""

            for (( int_i=0 ; int_i<${#arr_virtThreadSets[@]} ; int_i++ )); do
                str_line1+="${arr_virtThreadSets[$int_i]},";
            done

            # update parameters #
            if [[ ${str_line1: -1} == "," ]]; then
                str_line1=${str_line1::-1}
            fi

            str_output1="#isolcpus=$str_virtThreads nohz_full=$str_virtThreads rcu_nocbs=$str_virtThreads\n#TOTAL_THREADS_MASK=$hex_totalThreads_mask\n#HOST_THREADS_MASK=$hex_hostThreads_mask"

            echo -e $str_output1 > $str_logFile1
    }

# prompt #
    str_output1="CPU isolation (Static or Dynamic) is a feature which allocates system CPU threads to the host and Virtual machines (VMs).\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit\n\t'Static' is 'permanent' CPU isolation: installation will append to GRUB after VFIO setup.\n\tAlternatively, 'Dynamic' CPU isolation is flexible and on-demand: post-installation will execute as a libvirt hook script (per VM).\n"
    echo -e $str_output1

    str_output1="Setup 'Static' CPU isolation? [Y/n]: "
    ReadInput $str_output1

    case $str_input1 in
        "Y")
            echo -en "Executing CPU isolation setup... "
            ParseCPU
            echo -e "Complete.";;

        "N")
            echo -e "Exiting.";;
    esac

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0