#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

shopt -s nullglob
for int_IOMMU in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
    bool_hasVGA=false
    echo "IOMMU Group '${int_IOMMU##*/}':"

    for int_index in $int_IOMMU/devices/*; do
        str_thisIOMMU=`lspci -nnks ${int_index##*/} | grep -Eiv 'module|subsystem'`
        arr_devIndex_sum+=($int_index)
        arr_devDriver_sum+=(`lspci -nnks ${int_index##*/} | grep 'driver' | cut -d ':' -f2 | cut -d ' ' -f2`)
        arr_devHWID_sum+=(`lspci -nnks ${int_index##*/} | cut -d ' ' -f3`)
        arr_devName_sum+=(`lspci -ms ${int_index##*/} | cut -d '"' -f2`)
        arr_devType_sum+=(`lspci -ms ${int_index##*/} | cut -d '"' -f6`)

        str_thisIOMMU_DevType=`lspci -ms ${int_index##*/} | cut -d '"' -f6 | tr '[:lower:]' '[:upper:]'`

        if [[ $str_thisIOMMU_DevType == *'VGA'* || $str_thisIOMMU_DevType == *'GRAPHICS'* ]]; then
            bool_hasVGA=true
        fi

        echo -e "\t$str_thisIOMMU"
    done;

    if [[ $bool_hasVGA == true ]]; then
        echo "IOMMU Group '${int_IOMMU##*/}' has VGA."
        arr_IOMMU_VGA+=($int_IOMMU)
    else
        echo "IOMMU Group '${int_IOMMU##*/}' has NO VGA."
        arr_IOMMU_noVGA+=($int_IOMMU)
    fi
    # create arrays for vfio and non-vfio selection
    # create arrays for vga vfio and vga non-vfio selection


    echo
done;

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0