#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1. parse system memory.
# 2. ask user for input (hugepage size and num pages), continue if user input is valid.
# 3. save output to log, to be used for manual VFIO setup (executing this script alone) or in automated VFIO setup.
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

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# parameters #
    bool_missingFiles=false
    int_HostMemMaxK=$(cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1)     # sum of system RAM in KiB
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    readonly str_inFile1=$(find . -name *etc_libvirt_qemu.conf)
    readonly str_thisFile="${0##*/}"
    readonly str_logFile1="$str_thisFile.log"
    readonly str_outFile1="/etc/libvirt/qemu.conf"
    readonly str_oldFile1=$str_outFile1".old"

# prompt #
    str_output1="HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and lower overhead of memory-access (memory latency).\n"

    echo -e $str_output1
    echo -e "Executing Hugepages setup..."

# Hugepage size: validate input #
    declare -i int_count=0

    while true; do
        # attempt #
        if [[ $int_count -ge 3 ]]; then
            str_HugePageSize="1G"           # default selection
            echo -e "Exceeded max attempts. Default selection: ${str_HugePageSize}"

        else
            echo -en "Enter Hugepage size and byte-size. [2M/1G]: "
            read -r str_HugePageSize
            str_HugePageSize=$(echo $str_HugePageSize | tr '[:lower:]' '[:upper:]')
        fi

        # check input #
        case $str_HugePageSize in
            "2M"|"1G")
                break;;

            *)
                echo "Invalid input.";;
        esac

        ((int_count++))
    done

# Hugepage sum: validate input #
    declare -i int_count=0

    while true; do

        # attempt #
        if [[ $int_count -ge 3 ]]; then
            int_HugePageNum=$int_HugePageMax        # default selection
            echo "Exceeded max attempts. Default selection: ${int_HugePageNum}"

        else
            # Hugepage Size #
            if [[ $str_HugePageSize == "2M" ]]; then
                declare -i int_HugePageK=2048       # Hugepage size
                declare -i int_HugePageMin=2        # min HugePages
            fi

            if [[ $str_HugePageSize == "1G" ]]; then
                declare -i int_HugePageK=1048576    # Hugepage size
                declare -i int_HugePageMin=1        # min HugePages
            fi

            declare -i int_HostMemMinK=4194304                              # min host RAM in KiB
            declare -i int_HugePageMemMax=$int_HostMemMaxK-$int_HostMemMinK
            declare -i int_HugePageMax=$int_HugePageMemMax/$int_HugePageK   # max HugePages

            echo -en "Enter number of HugePages (n * $str_HugePageSize). [$int_HugePageMin <= n <= $int_HugePageMax pages]: "
            read -r int_HugePageNum
        fi

        # check input #
        if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then
            echo "Invalid input."
            ((int_count++))

        else
            # str_output1="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"   # shared variable with other function
            str_output1="#$str_HugePageSize #$int_HugePageNum"
        fi

        break
    done

# clear existing file #
    if [[ -e $str_logFile1 ]]; then
        rm $str_logFile1
    fi

# write to file #
    echo $str_output1 > $str_logFile1

## /etc/libvirt/qemu.conf ##
    str_output1="user = \"user\"\ngroup = \"user\""
    str_output2="hugetlbfs_mount = \"/dev/hugepages\""
    str_output3="cgroup_device_acl = [\n    \"/dev/null\", \"/dev/full\", \"/dev/zero\",\n    \"/dev/random\", \"/dev/urandom\",\n    \"/dev/ptmx\", \"/dev/kvm\",\n    \"/dev/rtc\",\"/dev/hpet\"\n]"

    if [[ -e $str_inFile1 ]]; then
        if [[ -e $str_outFile1 ]]; then
            mv $str_outFile1 $str_oldFile1      # create backup
        fi

        # write to file #
        while read -r str_line1; do
            if [[ $str_line1 == '#$str_output1'* ]]; then
                str_line1=$str_output1
            fi

            if [[ $str_line1 == '#$str_output2'* ]]; then
                str_line1=$str_output2
            fi

            if [[ $str_line1 == '#$str_output3'* ]]; then
                str_line1=$str_output3
            fi

            echo -e $str_line1 >> $str_outFile1
        done < $str_inFile1

        echo -e "Executing Hugepages setup... Complete.\n"
        systemctl enable libvirtd
        systemctl restart libvirtd
        echo -e "Review changes:\n\t'$str_outFile1'"

    else
        echo -e "Failed. File(s) missing:"
        echo -e "\t'$str_inFile1'"
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0