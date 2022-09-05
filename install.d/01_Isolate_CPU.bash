#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
#
#
#

exit 0

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# debug logfiles #
    readonly str_logFile1="$str_thisFile.log"

# prompt #
    str_output1="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and lower overhead of memory-access (memory latency).\n"
    # echo -e $str_output1
    echo -e "$0: Executing CPU isolation setup..."

# parameters #
    readonly declare -i int_totalCores=`cat /proc/cpuinfo | grep 'cpu cores' | uniq`
    readonly declare -i int_totalThreads=`cat /proc/cpuinfo | grep 'processor'`
    readonly declare -i int_multiThread=$(( $int_totalThreads / $int_totalCores ))
    readonly declare -i int_lastThread=$(( $int_totalThreads - 1 ))
    readonly str_totalThreads="0-$int_lastThread"
    declare -i int_hostCores=1                                                      # default value

# reserve remainder cores to host #
    # >= 4-core CPU, leave max 2
    if [[ $int_totalCores -ge 4 ]]; then
        int_hostCores=2

    # 2 or 3-core CPU, leave max 1
    elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then
        int_hostCores=1

    # 1-core CPU, do not reserve cores to virt
    else
        int_hostCores=$int_totalCores
    fi

    # parse total cores #
    for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do

        # reserve cores to host #
        if [[ $int_i -lt $int_hostCores ]]; then
            arr_hostCores+=( $int_i )

        # reserve cores to virt #
        else
            arr_virtCores+=( $int_i )
        fi
    done

# save output to string for cpuset and cpumask #
    # parse multi thread #
    declare -i int_i=1
    while [[ $int_i -le $int_multiThread ]]; do

        # parse host cores #
        for (( int_j=0 ; int_j<${arr_hostCores[@]} ; int_j++ )); do
            declare -i int_k=$(( int_j++ ))

            # update array of host threads, for cpumask #
            arr_hostThreads+=( $(( ${arr_hostCores[$int_j]} * $int_multiThread )) )

            # match next valid element, and diff is equal to 1, update temp array, for cpuset #
            if [[ ! -z ${arr_hostCores[$int_k]} && $(( ${arr_hostCores[$int_k]} - ${arr_hostCores[$int_j]} )) -eq 1 ]]; then
                declare -a arr_temp1=( ${arr_hostCores[0]}, ${arr_hostCores[$int_k]} )
            fi
        done

        # parse host cores #
        for (( int_j=0 ; int_j<${arr_virtCores[@]} ; int_j++ )); do
            declare -i int_k=$(( int_j++ ))

            # match next valid element, and diff is equal to 1, update temp array
            if [[ ! -z ${arr_virtCores[$int_k]} && $(( ${arr_virtCores[$int_k]} - ${arr_virtCores[$int_j]} )) -eq 1 ]]; then
                declare -a arr_temp2=( ${arr_virtCores[0]}, ${arr_virtCores[$int_k]} )
            fi
        done

        # format and update list of host threads #
        str_hostThreads+=$(( ${arr_temp1[0]} * $int_i ))"-"$(( ${arr_temp1[1]} * $int_i ))","
        str_virtThreads+=$(( ${arr_temp2[0]} * $int_i ))"-"$(( ${arr_temp2[1]} * $int_i ))","
        ((int_i++))
    done

    # remove last separator #
    if [[ ${str_hostThreads: -1} == "," ]]; then
        str_hostThreads=${str_hostThreads::-1}
    fi

    if [[ ${str_virtThreads: -1} == "," ]]; then
        str_virtThreads=${str_virtThreads::-1}
    fi

    str_output1=

    # find cpu mask #
    # readonly declare -i int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))

    # declare -i int_hostThreads_mask=0
    # for int_element in ${arr_hostThreads[@]}; do
    #     int_hostThreads_mask+=$(( 2 ** $int_element ))
    # done

    # int to hex #
    # readonly hex_totalThreads_mask=`printf '%x\n' $int_totalThreads_mask`
    # readonly hex_hostThreads_mask=`printf '%x\n' $int_hostThreads_mask`

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

# clear existing file #
    if [[ -e $str_logFile1 ]]; then
        rm $str_logFile1
    fi

# write to file #
    echo $str_output1 > $str_logFile1


IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0