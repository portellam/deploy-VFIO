#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1. check if related packages are installed, git repo exists, continue.
# 2. read hugepages logfile for vars, ask user input and calculate reasonable zram swap size.
# 3. save output to file, restart related services.
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

# parameters #
    str_logFile0=`find . -name *hugepages*bash* | grep -v log`
    declare -i int_count=0      # reset counter

# system files #
    str_outFile1="/etc/default/zramswap"
    str_outFile2="/etc/default/zram-swap"

# input files #
# none for file1
    str_inFile2=`find . -name *etc_default_zram-swap*`

# system file backups #
    str_oldFile1=$str_outFile1".old"
    str_oldFile2=$str_outFile2".old"

# debug logfiles #
    str_logFile0=`find . -name *Hugepages*log*`

# prompt #
    str_output1="ZRAM allocates RAM as a compressed swapfile.\n\tThe default compression method \"lz4\", at a ratio of 2:1 to 5:2, offers the greatest performance."

    echo -e $str_output1
    echo -e "Executing ZRAM-swap setup. Calculating..."

# parameters #
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    str_gitRepo="FoundObjects/zram-swap"
    str_gitUserName=`echo $str_gitRepo | cut -d '/' -f1`
    mkdir ./git

# check for zram-utils #
    if [[ -e $str_outFile1 ]]; then
        systemctl stop zramswap
        systemctl disable zramswap
    fi

# clone repo #
    if [[ ! `find -wholename *./git/$str_gitRepo*` ]]; then
        mkdir ./git/$str_gitUserName
        git clone https://www.github.com/$str_gitRepo ./git/$str_gitRepo
    fi

# execute repo #
    if [[ ! -z "./git/$str_gitRepo" ]]; then
        sh ./git/$str_gitRepo/install.sh
    fi

    if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then sudo swapoff /dev/zram*; fi   # disable ZRAM swap
    if [[ -z $str_oldFile2 ]]; then cp $str_outFile2 $str_oldFile2; fi                                 # backup config file

# find free memory #
    declare -i int_hostMemMaxG=$((int_HostMemMaxK/1048576))
    declare -i int_sysMemMaxG=$((int_hostMemMaxG+1))        # use modulus?

# check #
    if [[ -z $str_logFile0 ]]; then
        str_file=`find . -name *Hugepages*bash*`
        str_file=`echo ${str_file##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_file' and '$0'.\n"

        declare -i int_hostMemFreeG=$int_sysMemMaxG

        # setup ZRAM #
        echo -e "Total system memory: <= ${int_sysMemMaxG}G.\nIf 'Z == ${int_sysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."
    else

        while read -r str_line1; do
            if [[ $str_line1 == *"hugepagesz="* ]]; then str_hugePageSize=`echo $str_line1 | cut -d '=' -f2 | cut -d ' ' -f1`; fi       # parse hugepage size
            if [[ $str_line1 == *"hugepages="* ]]; then str_HugePageNum=`echo $str_line1 | cut -d '=' -f4`; fi                          # parse hugepage num
        done < $str_logFile0

        if [[ $str_hugePageSize == "2M" ]]; then declare -i int_hugePageSizeK=2048; fi
        if [[ $str_hugePageSize == "1G" ]]; then declare -i int_hugePageSizeK=1048576; fi

        int_HugePageNum=$str_HugePageNum

        # free memory #
        declare -i int_hugepagesMemG=$int_HugePageNum*$int_hugePageSizeK/1048576
        declare -i int_hostMemFreeG=$int_sysMemMaxG-$int_hugepagesMemG

        # setup ZRAM #
        echo -e "Free system memory after hugepages (${int_hugepagesMemG}G): <= ${int_hostMemFreeG}G."
    fi

    str_output1="Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): "
    echo -en $str_output1
    read -r int_ZRAM_sizeG

    while true; do

        # attempt #
        if [[ $int_count -ge 2 ]]; then
            ((int_ZRAM_sizeG=int_hostMemFreeG/2))      # default selection
            echo -e "Exceeded max attempts. Default selection: ${int_ZRAM_sizeG}G"
            break
        else
            if [[ -z $int_ZRAM_sizeG || $int_ZRAM_sizeG -lt 0 || $int_ZRAM_sizeG -ge $int_hostMemFreeG ]]; then
                echo -en "Invalid input.\n$str_output1"
                read -r int_ZRAM_sizeG
            else break; fi
        fi

        ((int_count++))     # increment counter
    done

# NOTE: leave as "! -z" (IS 'NOT' NULL), integers do not work with "-e" (IS 'NOT-NULL') #
    if [[ ! -z $int_ZRAM_sizeG ]]; then declare -i int_denominator=$int_sysMemMaxG/$int_ZRAM_sizeG; fi

# NOTE: leave as "! -z" (IS 'NOT' NULL), integers do not work with "-e" (IS 'NOT-NULL') #
# if input is valid #
    if [[ ! -z $int_denominator ]]; then
        str_output1="_zram_fraction=\"1/$int_denominator\""
    else
        str_output1=""
    fi

# /etc/default/zram-swap #
    if [[ -e $str_inFile2 ]]; then
        if [[ -e $str_outFile2 ]]; then
            mv $str_outFile2 $str_oldFile2      # create backup
        fi

        # write to file #
        while read -r str_line1; do
            if [[ $str_line1 == '#$str_output1'* && $str_output1 != "" ]]; then
                str_line1=$str_output1
            fi

            echo -e $str_line1 >> $str_outFile2
        done < $str_inFile2

        systemctl restart zram-swap     # restart service   # NOTE: do not enable/start zramswap.service?  # NOTE: test!
        # NOTE: in my setup, I prefer the git repo. I currently do not understand zram setup using the debian package/config file (zram pages are exact sizes compressed, not uncompressed as above).
        echo -e "Executing ZRAM-swap setup... Complete.\n"
        echo -e "Review changes:\n\t'$str_outFile2'"
    else
        echo -e "Failed. File(s) missing:"

        if [[ -z $str_inFile2 ]]; then
            echo -e "\t'$str_inFile2'"
        fi

        if [[ -z $str_logFile0 ]]; then
            echo -e "\t'$str_logFile0'"
        fi
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
