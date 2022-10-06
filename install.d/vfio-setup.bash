#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

function CheckIfUserIsRoot
{
    (exit 0)

    if [[ $( whoami ) != "root" ]]; then
        str_thisFile=$( echo ${0##/*} )
        str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_thisFile'"

        # (exit 1)      # same as below
        false           # same as above
    fi
}

function CreateBackupFromFile
{
    # behavior:
    #   create a backup file
    #   return boolean, to be used by main
    #

    (exit 0)
    echo -en "Backing up file...\t"

    # parameters #
    str_thisFile=$1

    # create false match statements before work begins, to catch exceptions
    # null exception
    if [[ -z $str_thisFile ]]; then
        (exit 254)
    fi

    # file not found exception
    if [[ ! -e $str_thisFile ]]; then
        (exit 253)
    fi

    # file not readable exception
    if [[ ! -r $str_thisFile ]]; then
        (exit 252)
    fi

    # work #
    # parameters #
    declare -r str_suffix=".old"
    declare -r str_thisDir=$( dirname $1 )
    declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

    # positive non-zero count
    if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then

        # parameters #
        declare -ir int_maxCount=5
        str_line=${arr_thisDir[0]}
        str_line=${str_line%"${str_suffix}"}        # substitution
        str_line=${str_line##*.}                    # ditto

        # check if string is a valid integer #
        if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
            declare -ir int_firstIndex="${str_line}"

        else
            (exit 254)
        fi

        for str_element in ${arr_thisDir[@]}; do
            if cmp -s $str_thisFile $str_element; then
                (exit 3)
                break
            fi
        done

        # if latest backup is same as original file, exit
        if cmp -s $str_thisFile ${arr_thisDir[-1]}; then
            (exit 3)
        fi

        # before backup, delete all but some number of backup files
        while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do
            if [[ -e ${arr_thisDir[0]} ]]; then
                rm ${arr_thisDir[0]}
                break
            fi
        done

        # if *first* backup is same as original file, exit
        if cmp -s $str_thisFile ${arr_thisDir[0]}; then
            (exit 3)
        fi

        # new parameters #
        str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
        str_line=${str_line##*.}                        # ditto

        # check if string is a valid integer #
        if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
            declare -i int_lastIndex="${str_line}"

        else
            (exit 254)
        fi

        (( int_lastIndex++ ))           # counter

        # source file is newer and different than backup, add to backups
        if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
            cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"

        elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
            (exit 3)

        else
            (exit 3)
        fi

    # no backups, create backup
    else
        cp $str_thisFile "${str_thisFile}.0${str_suffix}"
    fi

    # append output and return code
    case "$?" in
        0)
            echo -e "Successful."
            true;;

        3)
            echo -e "Skipped. No changes from most recent backup."
            true;;

        255)
            echo -e "Failed.";;

        254)
            echo -e "Failed. Exception: Null/invalid input.";;

        253)
            echo -e "Failed. Exception: File '$str_thisFile' does not exist.";;

        252)
            echo -e "Failed. Exception: File '$str_thisFile' is not readable.";;

        {131-255})
            false;;
    esac
}

function CreateFile
{
    (exit 0)
    echo -en "Creating file...\t"

    # null exception
    if [[ -z $1 ]]; then
        (exit 254)
    fi

    # file not found
    if [[ ! -e $1 ]]; then
        touch $1 &> /dev/null || (exit 255)

    else
        (exit 3)
    fi

    case "$?" in
        0)
            echo -e "Successful."
            true;;

        3)
            echo -e "Skipped. File '$1' exists."
            true;;

        255)
            echo -e "Failed. Could not create file '$1'.";;

        254)
            echo -e "Failed. Null exception/invalid input.";;

        {3-255})
            false;;
    esac
}

function DeleteFile
{
    (exit 0)
    echo -en "Deleting file...\t"

    # null exception
    if [[ -z $1 ]]; then
        (exit 254)
    fi

    # file not found
    if [[ ! -e $1 ]]; then
        (exit 3)

    else
        touch $1 &> /dev/null || (exit 255)
    fi

    case "$?" in
        0)
            echo -e "Successful."
            true;;

        3)
            echo -e "Skipped. File '$1' does not exist."
            true;;

        255)
            echo -e "Failed. Could not delete file '$1'.";;

        254)
            echo -e "Failed. Null exception/invalid input.";;

        {3-255})
            false;;
    esac
}

function ParseIOMMUandPCI
{
    (exit 254)
    echo -en "Parsing IOMMU groups...\t"

    # parameters #
    declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
    declare -a arr_DeviceIOMMU=()
    declare -a arr_DevicePCI_ID=()
    declare -a arr_DeviceDriver=()
    declare -a arr_DeviceName=()
    declare -a arr_DeviceType=()
    declare -a arr_DeviceVendor=()
    bool_missingDriver=false
    bool_foundVFIO=false

    # parse list of IOMMU groups #
    for str_line1 in $( find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V ); do
        (exit 0)

        # parameters #
        str_thisIOMMU=$( basename $str_line1 )

        # parse given IOMMU group for PCI IDs #
        for str_line2 in $( ls ${str_line1}/devices ); do

            # parameters #
            # save output of given device #
            str_thisDevicePCI_ID="${str_line2##"0000:"}"
            str_thisDeviceName="$( lspci -ms ${str_line2} | cut -d '"' -f6 )"
            str_thisDeviceType="$( lspci -ms ${str_line2} | cut -d '"' -f2 )"
            str_thisDeviceVendor="$( lspci -ms ${str_line2} | cut -d '"' -f4 )"
            str_thisDeviceDriver="$( lspci -ks ${str_line2} | grep driver | cut -d ':' -f2 )"

            if [[ -z $str_thisDeviceDriver ]]; then
                str_thisDeviceDriver="N/A"
                bool_missingDriver=true

            else
                if [[ $str_thisDeviceDriver == *"vfio-pci"* ]]; then
                    str_thisDeviceDriver="N/A"
                    bool_foundVFIO=true

                else
                    str_thisDeviceDriver="${str_thisDeviceDriver##" "}"
                fi
            fi

            # parameters #
            arr_DeviceIOMMU+=( "$str_thisIOMMU" )
            arr_DevicePCI_ID+=( "$str_thisDevicePCI_ID" )
            arr_DeviceDriver+=( "$str_thisDeviceDriver" )
            arr_DeviceName+=( "$str_thisDeviceName" )
            arr_DeviceType+=( "$str_thisDeviceType" )
            arr_DeviceVendor+=( "$str_thisDeviceVendor" )
        done
    done

    # prioritize worst exit code (place last)
    case true in
        $bool_missingDriver)
            (exit 3);;

        $bool_foundVFIO)
            (exit 254);;
    esac

    case "$?" in
            # function never failed
            0)
                echo -e "Successful."
                true;;

            3)
                echo -e "Successful. One or more external PCI device(s) missing drivers."
                true;;

            255)
                echo -e "Failed.";;

            254)
                echo -e "Failed. Exception: No devices found.";;

            253)
                echo -e "Failed. Exception: Existing VFIO setup found.";;

            # function failed at a given point, inform user
            {131-255})
                false;;
        esac
}

function WriteVarToFile
{
    (exit 0)
    echo -en "Writing to file...\t"

    # null exception
    if [[ -z $1 || -z $2 ]]; then
        (exit 254)
    fi

    # file not found exception
    if [[ ! -e $1 ]]; then
        (exit 253)
    fi

    # file not readable exception
    if [[ ! -r $1 ]]; then
        (exit 252)
    fi

    # if a given element is a string longer than one char, the var is an array #
    for str_element in ${2}; do
        if [[ ${#str_element} -gt 1 ]]; then
            bool_varIsAnArray=true
            break
        fi
    done

    if [[ "$?" -eq 0 ]]; then

        # write array to file #
        if [[ $bool_varIsAnArray == true ]]; then
            for str_element in ${2}; do
                echo $str_element >> $1 || (exit 255)
            done

        # write string to file #
        else
            echo $2 >> $1 || (exit 255)
        fi
    fi

    case "$?" in
        0)
            echo -e "Successful."
            true;;

        255)
            echo -e "Failed.";;

        254)
            echo -e "Failed. Null exception/invalid input.";;

        253)
            echo -e "Failed. File '$1' does not exist.";;

        252)
            echo -e "Failed. File '$1' is not readable.";;

        {131-255})
            false;;
    esac
}

function ReadInput
{
    (exit 0)

    # parameters #
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

function SetupHugepages
{
    (exit 0)

    echo -e "HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and lower overhead of memory-access (memory latency).\n"

    ReadInput "Execute Hugepages setup?"

    declare -i int_count=0

    while true; do
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

    declare -i int_count=0

    while true; do
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

}

