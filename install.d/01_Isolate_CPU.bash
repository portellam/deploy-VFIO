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

# parameters #
    bool_missingFiles=false
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB

# debug logfiles #
    str_logFile1=$(pwd)'/'$0'.log'

# prompt #
    str_output1="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and lower overhead of memory-access (memory latency).\n"

    echo -e $str_output1
    echo -e "$0: Executing Hugepages setup..."


IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0