#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
#
#
#

#
# output:
#
# host threads, by pairs
# virt threads, by pairs
# complete arrays of each thread for either host and virt
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# debug logfiles #
    readonly str_logFile1="$str_thisFile.log"

# prompt #
    str_output="CPU isolation is a feature which statically allocates System CPU threads to the host and Virtual machines.\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit.\n\nExecuting CPU isolation setup..."
    echo -e $str_output1

# parameters #
    readonly arr_coresByThread=(`cat /proc/cpuinfo | grep 'core id' | cut -d ':' -f2 | cut -d ' ' -f2`)
    readonly int_totalCores=`cat /proc/cpuinfo | grep 'cpu cores' | uniq | cut -d ':' -f2 | cut -d ' ' -f2`
    readonly int_totalThreads=`cat /proc/cpuinfo | grep 'siblings' | uniq | cut -d ':' -f2 | cut -d ' ' -f2`
    readonly int_multiThread=$(( $int_totalThreads / $int_totalCores ))
    # readonly int_lastThread=$(( $int_totalThreads - 1 ))
    # readonly str_totalThreads="0-$int_lastThread"
    declare -a arr_totalCores=()
    # declare -a arr_hostCores=()
    declare -a arr_hostThreads=()
    # declare -a arr_virtCores=()
    declare -a arr_virtThreads=()
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

# group threads by core id #
    for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do

        # parameters #
        str_line1=""
        declare -i int_thisCore=${arr_coresByThread[int_i]}

        for (( int_count=0 ; int_count<$int_multiThread ; int_count++ )); do

            # parameters #
            int_thisThread=$((int_thisCore+int_totalCores*int_count))
            str_line1+="$int_thisThread,"
        done

        # update parameters #
        if [[ ${str_line1: -1} == "," ]]; then
            str_line1=${str_line1::-1}
        fi

        arr_totalThreads+=("$str_line1")

        # save output for cpu isolation (host) #
        if [[ $int_thisCore -lt $int_hostCores ]]; then
            arr_hostThreads+=("$str_line1")

        # save output for cpuset/cpumask (qemu cpu pinning) #
        else
            arr_virtThreads+=("$str_line1")
        fi
    done

# update parameters #
    readonly arr_totalThreads
    readonly arr_hostThreads
    readonly arr_virtThreads

    # if [[ ${str_hostThreads: -1} == "," ]]; then
    #     readonly str_hostThreads=${str_hostThreads::-1}
    # fi

    # if [[ ${str_virtThreads: -1} == "," ]]; then
    #     readonly str_virtThreads=${str_virtThreads::-1}
    # fi

# # save output to string for cpuset and cpumask #
#     # parse multi thread #
#     declare -i int_i=1
#     while [[ $int_i -le $int_multiThread ]]; do

#         # parse host cores #
#         for (( int_j=0 ; int_j<${arr_hostCores[@]} ; int_j++ )); do
#             declare -i int_k=$(( int_j++ ))

#             # update array of host threads, for cpumask #
#             arr_hostCores+=( $(( ${arr_hostCores[$int_j]} * $int_multiThread )) )

#             # match next valid element, and diff is equal to 1, update temp array, for cpuset #
#             if [[ ! -z ${arr_hostCores[$int_k]} && $(( ${arr_hostCores[$int_k]} - ${arr_hostCores[$int_j]} )) -eq 1 ]]; then
#                 declare -a arr_temp1=( ${arr_hostCores[0]}, ${arr_hostCores[$int_k]} )
#             fi
#         done

#         # parse host cores #
#         for (( int_j=0 ; int_j<${arr_virtCores[@]} ; int_j++ )); do
#             declare -i int_k=$(( int_j++ ))

#             # match next valid element, and diff is equal to 1, update temp array
#             if [[ ! -z ${arr_virtCores[$int_k]} && $(( ${arr_virtCores[$int_k]} - ${arr_virtCores[$int_j]} )) -eq 1 ]]; then
#                 declare -a arr_temp2=( ${arr_virtCores[0]}, ${arr_virtCores[$int_k]} )
#             fi
#         done

#         # format and update list of host threads #
#         str_hostThreads+=$(( ${arr_temp1[0]} * $int_i ))"-"$(( ${arr_temp1[1]} * $int_i ))","
#         str_virtThreads+=$(( ${arr_temp2[0]} * $int_i ))"-"$(( ${arr_temp2[1]} * $int_i ))","
#         ((int_i++))
#     done

#     # update parameters #
#     if [[ ${str_hostThreads: -1} == "," ]]; then
#         readonly str_hostThreads=${str_hostThreads::-1}
#     fi

#     if [[ ${str_virtThreads: -1} == "," ]]; then
#         readonly str_virtThreads=${str_virtThreads::-1}
#     fi

    # str_output1=""

    # find cpu mask #
    # readonly declare -i int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))

    # declare -i int_hostThreads_mask=0
    # for int_element in ${arr_hostCores[@]}; do
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

# debug prompt #
    function DebugOutput
    {
        echo -e "$0: ========== DEBUG PROMPT ==========\n"

        echo -e '${#arr_coresByThread[@]} == '"'${#arr_coresByThread[@]}'"
        echo -e '${#arr_totalThreads[@]} == '"'${#arr_totalThreads[@]}'"
        echo -e '$int_totalCores == '"'$int_totalCores'"
        echo -e '$int_totalThreads == '"'$int_totalThreads'"
        # echo -e '$int_totalThreads_mask == '"'$int_totalThreads_mask'"
        echo -e '${#arr_hostThreads[@]} == '"'${#arr_hostThreads[@]}'"
        echo -e '$int_hostCores == '"'$int_hostCores'"
        # echo -e '$int_hostThreads_mask == '"'$int_hostThreads_mask'"
        # echo -e '$int_lastThread == '"'$int_lastThread'"
        echo -e '$int_multiThread == '"'$int_multiThread'"
        echo -e '${#arr_virtThreads[@]} == '"'${#arr_virtThreads[@]}'"

        for (( i=0 ; i<${#arr_coresByThread[@]} ; i++ )); do echo -e "$0: '$""{arr_coresByThread[$i]}'\t= '${arr_coresByThread[$i]}'"; done && echo
        for (( i=0 ; i<${#arr_totalThreads[@]} ; i++ )); do echo -e "$0: '$""{arr_totalThreads[$i]}'\t= '${arr_totalThreads[$i]}'"; done && echo
        for (( i=0 ; i<${#arr_hostThreads[@]} ; i++ )); do echo -e "$0: '$""{arr_hostThreads[$i]}'\t= '${arr_hostThreads[$i]}'"; done && echo
        for (( i=0 ; i<${#arr_virtThreads[@]} ; i++ )); do echo -e "$0: '$""{arr_virtThreads[$i]}'\t= '${arr_virtThreads[$i]}'"; done && echo

        echo -e "\n$0: ========== DEBUG PROMPT =========="
        exit 0
    }

    DebugOutput     # uncomment to debug here

# clear existing file #
    if [[ -e $str_logFile1 ]]; then
        rm $str_logFile1
    fi

# write to file #
    echo $str_output1 > $str_logFile1


IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0