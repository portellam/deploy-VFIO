#!/bin/bash sh

exit 0

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# parameters #


# set vcpu #
SetVCPU {
    declare -i int_numSocket=`echo $(lscpu | grep -i 'socket' | grep -iv 'core' | cut -d ':' -f2)`
    declare -i int_numCore=`cat /proc/cpuinfo | grep 'cpu cores' | uniq`
    declare -i int_numThread=`cat /proc/cpuinfo | grep 'processor'`

    if [[ $int_numCore -ge 4 ]]; then
        int_vOffset=2
        #int_vCore=$(( int_numSocket * ( $int_numCore - $int_vOffset ) ))
    else if [[ $int_numCore == 3 ]]; then
        int_vOffset=1
        #int_vCore=$(( int_numSocket * 2 ))
        int_vCore=2
    else if [[ $int_numCore == 2 ]]; then
        int_vOffset=0
        #int_vCore=$int_numSocket
        int_vCore=1
    else if [[ $int_numCore == 2 ]]; then
        int_vCore=0
        echo "$0: Insufficient host resources (CPU cores). Skipping."
        #exit 0
    fi
}

# check for Hugepages support #
CheckHugepages {
    str_file1=`find . -name *hugepages*log`

    # match, save input and suffix to VM name #
    if [[ -z $str_file ]]; then
        echo -e "$0: Hugepages logfile does not exist. Skipping."

    # false match, prompt user #
    else
        while read str_line; do

            # parse hugepage size #
            if [[ $str_line == *"hugepagesz="* ]]; then
                str_hugepageSize=`echo $str_line | cut -d '=' -f2`
            fi

            # parse hugepage num #
            if [[ $str_line == *"hugepages="* ]]; then
                int_hugepageNum=`echo $str_line | cut -d '=' -f2`
            fi
        done < $str_file

        str_machineName+="_"$int_hugepageNum$str_hugepageSize
    fi
}

# check for Evdev support #
CheckEvdev {
    str_file1=`find . -name *evdev*log`
    declare -a arr_evdev

    echo -e "$0: Parsing Event devices."

    # match, save input and suffix to VM name #
    if [[ -e $str_file1 ]]; then
        while read str_line; do
            if [[ $str_line == *"/dev/input/"* ]]; then
                arr_evdev+=($str_line)
            fi
        done < $str_file1

    # false match, prompt user #
    else
        echo -e "$0: Evdev logfile does not exist."
    fi

    echo -e "$0: Event devices found: ${#arr_evdev[@]}"

    if [[ ${#arr_evdev[@]} -gt 0 ]]; then
        str_machineName+="_evdev" 
    fi
}

# scream?

exit 0