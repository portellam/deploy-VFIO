#!/bin/bash sh

# function steps #
# 1a.   Parse PCI and IOMMU groups, note each IOMMU group passedthrough.
# 1b.   No existing VFIO setup, warn user and immediately exit.
# 2a.   Create VM templates, with every possible config (excluding one given IOMMU group). Setup hugepages and other tweaks.
# 2b.   Set qemu enlightenments: evdev, hostdev (given VGA).
# 3.    Save VM templates to XML format, and output to directory. Restart libvirt to refresh.
#

exit 0

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

## user input ##
str_input1=""

## parameters ##
bool_readNextLine=false
declare -a arr_compgen=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h`)  # IOMMU ID and Bus ID, sorted by IOMMU ID (left-most digit)
declare -a arr_lspci=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)            # dev name, Bus ID, and (sometimes) driver, sorted
declare -a arr_lspci_busID=(`lspci -m | cut -d '"' -f 1`)                               # Bus ID, sorted        (ex '01:00.0') 
declare -a arr_lspci_HWID=(`lspci -n | cut -d ' ' -f 3`)                                # HW ID, sorted         (ex '10de:1b81')
declare -a arr_lspci_type=(`lspci -m | cut -d '"' -f 2 | tr '[:lower:]' '[:upper:]'`)   # dev type, sorted      (ex 'VGA', 'GRAPHICS')
declare -a arr_lspci_driverName=()
declare -a arr_lspci_IOMMUID                                                            # strings of index(es) of every Bus ID and entry, sorted by IOMMU ID
declare -a arr_lspci_VFIO                                                               # strings of index(es) of every Bus ID and entry, sorted by IOMMU ID
##

## find and sort drivers by Bus ID (lspci) ##
# parse Bus ID #
for (( int_i=0 ; int_i<${#arr_lspci_busID[@]} ; int_i++ )); do

    bool_readNextLine=false
    str_thatBusID=${arr_lspci_busID[$int_i]}
    #echo "$0: str_thatBusID == $str_thatBusID"

    # parse lspci info #
    for str_line1 in ${arr_lspci[@]}; do

        # 1 #
        # match boolean and driver, add to list #
        if [[ $bool_readNextLine == true && $str_line1 == *"driver"* ]]; then
            str_thisDriverName=`echo $str_line1 | grep "driver" | cut -d ' ' -f5`

            # vfio driver found, note input, add to list and update boolean #
            if [[ $str_thisDriverName == 'vfio-pci' ]]; then
                bool_isVFIOsetup=true
            fi
            #

            arr_lspci_driverName+=($str_thisDriverName)
            break
        fi
        #

        # 1 #
        # match boolean and false match line, add to list, reset boolean #
        if [[ $bool_readNextLine == true && $str_line1 != *"driver"* ]]; then
            arr_lspci_driverName+=("NO_DRIVER_FOUND")
            break
        fi

        # 2 #
        # match Bus ID, update boolean #
        if [[ $str_line1 == *$str_thatBusID* ]]; then
            bool_readNextLine=true
        fi
        #
    done
    #
done
##

## find and sort IOMMU IDs by Bus ID (lspci) ##
# parse list of Bus IDs #
for str_lspci_busID in ${arr_lspci_busID[@]}; do

    str_lspci_busID=${str_lspci_busID::-1}                                  # valid element
    #echo "$0: str_lspci_busID == '$str_lspci_busID'"

    # parse compgen info #
    for str_compgen in ${arr_compgen[@]}; do

        str_thisBusID=`echo $str_compgen | sort -h | cut -d '/' -f7`
        str_thisBusID=${str_thisBusID:5:10}                                 # valid element
        #echo "$0: str_thisBusID == $str_thisBusID"
        str_thisIOMMUID=`echo $str_compgen | sort -h | cut -d '/' -f5`      # valid element

        # match Bus ID, add IOMMU ID at index #
        if [[ $str_thisBusID == $str_lspci_busID ]]; then
            arr_lspci_IOMMUID+=($str_thisIOMMUID)                           # add to list
            break
        fi
        #
    done
    #
done
##

## parameters ##
readonly arr_lspci_driverName
readonly arr_lspci_IOMMUID
##

for str_lspci_driverName in ${arr_lspci_driverName[@]}; do
    echo "$0: str_lspci_driverName == $str_lspci_driverName"
done

for str_lspci_IOMMUID in ${arr_lspci_IOMMUID[@]}; do
    echo "$0: str_lspci_IOMMUID == $str_lspci_IOMMUID"
done


# sort IOMMU groups, add devices to XML
for (( int_i=0 ; int_i<${#arr_lscpi_IOMMUID[@]} ; int_i++ )); do

    # match VFIO device #
    if [[ ${arr_lspci_driverName[$int_i]} == "vfio-pci" ]]; then

        # add to XML

        # match VGA device #
        if [[ ${arr_lspci_type[$int_i]} == *"VGA"* && ${arr_lspci_type[$int_i]} == *"GRAPHICS"* ]]; then

            # create new XML for each VGA, set each VGA as hostdev

        fi

    fi
    #
done
#

# read hugepages from grub #

# read evdev from '/etc/libvirt/qemu.conf' or logfile

# name XML's as '0_template_VM_Q35_UEFI_[num_hugepages][hugepage_size]_[EVDEV]_GPU[num_index_of_hostdev_VGA]'

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo "$0: Exiting."
exit 0