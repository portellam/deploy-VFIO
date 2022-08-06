#!/bin/bash sh

# function steps #
# 1. check if related packages are installed, git repo exists, continue.
# 2. read hugepages logfile for vars, ask user input and calculate reasonable zram swap size.
# 3. save output to file, restart related services.
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# parameters #
str_hugepages=`find . -name *hugepages*bash* | grep -v log`
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
str_logFile0=`find . -name *hugepages*log*`

# prompt #
str_output1="$0: ZRAM allocates RAM as a compressed swapfile.\n\tThe default compression method \"lz4\", at a ratio of 2:1 to 5:2, offers the greatest performance."

echo -e $str_output1
echo -e "$0: Executing ZRAM-swap setup. Calculating..."

# parameters #
int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
str_GitHub_Repo="FoundObjects/zram-swap"

# check for zram-utils #
if [[ -e $str_outFile1 ]]; then
    sudo systemctl stop zramswap
    sudo systemctl disable zramswap
fi

if [[ -z "~/git/$str_GitHub_Repo" ]]; then
    sudo mkdir ~/git
    sudo mkdir ~/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
    cd ~/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
    git clone https://www.github.com/$str_GitHub_Repo
fi

# check for zram-swap #
if [[ -z $str_outFile2 ]]; then
    cd ~/git/$str_GitHub_Repo
    sh ./install.sh
fi

if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then sudo swapoff /dev/zram*; fi   # disable ZRAM swap
if [[ -z $str_oldFile2 ]]; then cp $str_outFile2 $str_oldFile2; fi                                 # backup config file

# find free memory #
declare -i int_HostMemMaxG=$((int_HostMemMaxK/1048576))
declare -i int_SysMemMaxG=$((int_HostMemMaxG+1))        # use modulus?

# check #
if [[ -z $str_file0 ]]; then
    echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_hugepages' and '$0'.\n"

    declare -i int_HostMemFreeG=$int_SysMemMaxG

    # setup ZRAM #
    echo -e "$0: Total system memory: <= ${int_SysMemMaxG}G.\n$0: If 'Z == ${int_SysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."
else

    while read str_line1; do
        if [[ $str_line1 == *"hugepagesz="* ]]; then str_HugePageSize=`echo $str_line1 | cut -d '=' -f2`; fi      # parse hugepage size
        if [[ $str_line1 == *"hugepages="* ]]; then str_HugePageNum=`echo $str_line1 | cut -d '=' -f2`; fi        # parse hugepage num
    done < $str_file0

    if [[ $str_HugePageSize == "2M" ]]; then declare -i int_HugePageSizeK=2048; fi
    if [[ $str_HugePageSize == "1G" ]]; then declare -i int_HugePageSizeK=1048576; fi

    int_HugePageNum=$str_HugePageNum

    # free memory #
    declare -i int_HugepagesMemG=$int_HugePageNum*$int_HugePageSizeK/1048576
    declare -i int_HostMemFreeG=$int_SysMemMaxG-$int_HugepagesMemG

    # setup ZRAM #
    echo -e "$0: Free system memory after hugepages (${int_HugepagesMemG}G): <= ${int_HostMemFreeG}G."
fi

str_output1="$0: Enter zram-swap size in G (0G < n < ${int_HostMemFreeG}G): "
echo -en $str_output1
read -r int_ZRAM_SizeG

while true; do

    # attempt #
    if [[ $int_count -ge 2 ]]; then
        ((int_ZRAM_SizeG=int_HostMemFreeG/2))      # default selection
        echo -e "$0: Exceeded max attempts. Default selection: ${int_ZRAM_SizeG}G"
        break
    else
        if [[ -z $int_ZRAM_SizeG || $int_ZRAM_SizeG -lt 0 || $int_ZRAM_SizeG -ge $int_HostMemFreeG ]]; then
            echo -en "$0: Invalid input.\n$str_output1"
            read -r int_ZRAM_SizeG
        else break; fi
    fi

    ((int_count++))     # increment counter
done

# NOTE: leave as "! -z" (IS 'NOT' NULL), integers do not work with "-e" (IS 'NOT-NULL') #
if [[ ! -z $int_ZRAM_SizeG ]]; then declare -i int_denominator=$int_SysMemMaxG/$int_ZRAM_SizeG; fi

# NOTE: leave as "! -z" (IS 'NOT' NULL), integers do not work with "-e" (IS 'NOT-NULL') #
# if input is valid #
if [[ ! -z $int_denominator ]]; then    
    sudo systemctl restart zram-swap     # restart service   # NOTE: do not enable/start zramswap.service?  # NOTE: test!
    # NOTE: in my setup, I prefer the git repo. I currently do not understand zram setup using the debian package/config file (zram pages are exact sizes compressed, not uncompressed as above).
fi
#

# /etc/default/zram-swap #
str_output1="_zram_fraction=\"1/2\""

if [[ -e $str_inFile2 ]]; then
    if [[ -e $str_outFile2 ]]; then
        mv $str_outFile2 $str_oldFile2      # create backup
    fi

    # write to file #
    while read -r str_line1; do
        if [[ $str_line1 == '#$str_output1'* ]]; then
            str_line1=$str_output1
        fi

        echo -e $str_line1 >> $str_outFile2
    done < $str_inFile2

    echo -e "$0: Executing ZRAM-swap setup... Complete.\n"
    echo -e "$0: Review changes:\n\t'$str_outFile2'"
else
    echo -e "Failed. File(s) missing:"
    echo -e "\t'$str_inFile2'"
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
