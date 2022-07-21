#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# parameters #
str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
#

# prompt #
declare -i int_count=0      # reset counter
str_output1="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

echo -e $str_output1
#

# Hugepage size: validate input #
str_HugePageSize=$str6
str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

while true; do
    # attempt #
    if [[ $int_count -ge 3 ]]; then
        echo "$0: Exceeded max attempts."
        str_HugePageSize="1G"           # default selection
    else
        echo -en "$0: Enter Hugepage size and byte-size. [2M/1G]: "
        read -r str_HugePageSize
        str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`
    fi
    #

    # check input #
    case $str_HugePageSize in
        "2M"|"1G")
            break;;
        *)
            echo "$0: Invalid input.";;
    esac
    #

    ((int_count++))     # increment counter
done
#

# Hugepage sum: validate input #
int_HugePageNum=$str7
declare -i int_count=0      # reset counter

while true; do
    # attempt #
    if [[ $int_count -ge 3 ]]; then
        echo "$0: Exceeded max attempts."
        int_HugePageNum=$int_HugePageMax        # default selection
    else
        # Hugepage Size #
        if [[ $str_HugePageSize == "2M" ]]; then
            #str_prefixMem="M"
            declare -i int_HugePageK=2048       # Hugepage size
            declare -i int_HugePageMin=2        # min HugePages
        fi

        if [[ $str_HugePageSize == "1G" ]]; then
            #str_prefixMem="G"
            declare -i int_HugePageK=1048576    # Hugepage size
            declare -i int_HugePageMin=1        # min HugePages
        fi

        declare -i int_HostMemMinK=4194304                              # min host RAM in KiB
        declare -i int_HugePageMemMax=$int_HostMemMaxK-$int_HostMemMinK
        declare -i int_HugePageMax=$int_HugePageMemMax/$int_HugePageK   # max HugePages

        echo -en "$0: Enter number of HugePages (n * $str_HugePageSize). [$int_HugePageMin <= n <= $int_HugePageMax pages]: "
        read -r int_HugePageNum
        #
    fi
    #

    # check input #
    if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then
        echo "$0: Invalid input."
        ((int_count++))     # increment counter
    else    
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"   # shared variable with other function
        echo -e "$0: Writing logfile. Contents: partial text for GRUB menu entry."
        
        str_file1=$(pwd)'/'$0'.log'
        echo $str_GRUB_CMDLINE_Hugepages > $str_file1
        break
    fi
    #
done
#

exit 0