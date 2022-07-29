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
#

## parameters ##
declare -i int_hostSocket=`echo $(lscpu | grep -Ei "socket" | grep -iv "core" | cut -d ':' -f2)`
declare -i int_hostCore=`echo $(lscpu | grep -Ei "core" | grep -Eiv "name|thread" | cut -d ':' -f2)`
declare -i int_hostThread=`echo $(lscpu | grep -Ei "thread" | cut -d ':' -f2)`

str_dir1="/etc/libvirt/qemu"

declare -a arr_compgen=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h`)  # IOMMU ID and Bus ID, sorted by IOMMU ID (left-most digit)
declare -a arr_lspci=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)            # dev name, Bus ID, and (sometimes) driver, sorted
declare -a arr_lspci_busID=(`lspci -m | cut -d '"' -f 1`)                               # Bus ID, sorted        (ex '01:00.0') 
declare -a arr_lspci_HWID=(`lspci -n | cut -d ' ' -f 3`)                                # HW ID, sorted         (ex '10de:1b81')
declare -a arr_lspci_type=(`lspci -m | cut -d '"' -f 2 | tr '[:lower:]' '[:upper:]'`)   # dev type, sorted      (ex 'VGA', 'GRAPHICS')

declare -a arr_lspci_driverName=()
declare -a arr_lspci_IOMMUID=()                                                         # strings of index(es) of every Bus ID and entry, sorted by IOMMU ID
declare -a arr_evdev=()

declare -i int_hugepageNum=0
str_hugepageSize=""

str_machineName="template_VM_Q35_UEFI"
##

# add support for socket count #


# set vcore count #
if [[ $int_hostCore -ge 4 ]]; then
    int_vCore=$int_hostSocket*($int_hostCore-2)
else if [[ $int_hostCore == 3 ]]; then
    int_vCore=$int_hostSocket*2
else if [[ $int_hostCore == 2 ]]; then
    int_vCore=$int_hostSocket
else if [[ $int_hostCore == 2 ]]; then
    int_vCore=0
    echo "$0: Insufficient host resources (CPU cores). Exiting."
    exit 0
fi
#

declare -i int_vThread=$int_vCore*$int_hostThread

# set vcpu placement as such #
# save first two cores to host
# use rest for VM #
# start at core index '3' and add to vcpu placement
# if smt enabled (threads > 1), alt between core and thread for vcpu placement


## check for hugepages logfile ##
str_file1=`ls $(pwd)/functions | grep -i 'hugepages' | grep -i '.log'`

if [[ -z $str_file0 ]]; then
    echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute "`ls $(pwd)/functions | grep -i 'hugepages' | grep -i '.bash'`"'.\n"

else
    while read str_line1; do

        # parse hugepage size #
        if [[ $str_line1 == *"hugepagesz="* ]]; then
            str_hugepageSize=`echo $str_line1 | cut -d '=' -f2`
        fi
        #

        # parse hugepage num #
        if [[ $str_line1 == *"hugepages="* ]]; then
            int_hugepageNum=`echo $str_line1 | cut -d '=' -f2`
        fi
        #   
    done < $str_file1

    str_machineName+="_"$int_hugepageNum$str_hugepageSize
fi
##

## check for EVDEV ##
str_file2="/etc/libvirt/qemu.conf"
bool_readNextLine=false

while read str_line1; do

    #if [[ $str_line1 == *"# END #"* ]]; then
        #bool_readNextLine=false
        #break
    #fi

    #if [[ $str_line1 == *"# START #"* ]]; then
        #bool_readNextLine=true
    #fi

    if [[ $bool_readNextLine == true && $str_line1 == *"/dev/input/"* ]]; then
        arr_evdev+=(`echo $str_line1 | cut -d ',' -f1 | cut -d '"' -f2`)
    fi

    if [[ $str_line1 == *"cgroup_device_acl = ["* ]]; then
        bool_readNextLine=true
        str_machineName+="_EVDEV"
    fi

    if [[ $str_line1 == *"/dev/null"*|*"/dev/full"*|*"/dev/zero"*|*"/dev/random"*|*"/dev/urandom"*|*"/dev/ptmx"*|*"/dev/kvm"*|*"/dev/rtc"*|*"/dev/hpet" ]]; then
        bool_readNextLine=false
        break
    fi    

done < $str_file2
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


# sort IOMMU groups, add devices to list of vfio devices
for (( int_i=0 ; int_i<${#arr_lscpi_IOMMUID[@]} ; int_i++ )); do

    # match VFIO device #
    if [[ ${arr_lspci_driverName[$int_i]} == "vfio-pci" ]]; then

        # add to XML
        arr_lspci_VFIO+=($int_i)

        # match VGA device #
        if [[ ${arr_lspci_type[$int_i]} == *"VGA"* && ${arr_lspci_type[$int_i]} == *"GRAPHICS"* ]]; then
           arr_lspci_VFIO_VGA+=($int_i)
        fi
    fi
    #
done
#

# parse VFIO devices, create XML templates #
if [[ -e $arr_lspci_VFIO ]]; then

    echo -e "$0: VFIO devices found."

    for int_lspci_VFIO in ${arr_lspci_VFIO[@]}; do
        # write to XML here
        break
    done

    # parse VFIO VGA devices, create new XML for different primary VM boot VGA and append VM name #
    if [[ -e $arr_lspci_VFIO_VGA ]]; then

        echo -e "$0: VFIO VGA devices found."

        for (( int_i=0 ; int_i<${#arr_lspci_VFIO_VGA[@]} ; int_i++ )); do
            int_lspci_VFIO_VGA=${arr_lspci_VFIO_VGA[$int_i]}
            str_thisMachineName=$str_machineName"GPU"$int_lspci_VFIO_VGA
        done

        else

        echo -e "$0: No VFIO VGA devices found."
    fi
    #

else
    echo -e "$0: No VFIO devices found."
fi
#

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo "$0: Exiting."
exit 0