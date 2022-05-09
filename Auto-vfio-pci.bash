#!/bin/bash

########## README ##########

# Maintainer: github/portellam

# TL;DR:
# Generate and/or Regenerate a VFIO setup (Multi-Boot or Static). VFIO for Dummies.

# Long version:
# Run at system-setup or whenever a hardware change occurs.
# Parses Bash for list of External PCI devices ( Bus ID, Hardware ID, and Kernel driver ). External refers to PCI Bus ID 01:00.0 onward.
# User may implement:
#   * Multi-Boot setup (includes some Static setup) or Static setup.
#       - Multi-Boot:   change Xorg VGA device on-the-fly.
#       - Static:       set Xorg VGA device statically.
#   * Hugepages             == static allocation of RAM for zero memory fragmentation and reduced memory latency.
#   * Event devices (Evdev) == virtual Keyboard-Mouse switch.
#   * ZRAM swapfile         == compressed RAM, to reduce Host lock-up from over-allocated Host memory.

########## pre-main ##########

# check if sudo #
if [[ `whoami` != "root" ]]; then

    echo "WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0

fi
#

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# debug first input #
echo "\$1: $1"          # perm v. multiboot [Y/B or N/P]
echo "\$2: $2"          # enable hugepages  [Y/H or N]
echo "\$3: $3"          # set size          [2M or 1G]
echo "\$4: $4"          # set num           [min or max]
echo "\$5: $5"          # enable Evdev      [Y/E or N]
echo "\$6: $6"          # enable Zram       [Y/Z or N]
# example:              sudo bash script_name.sh b h 1g 24 e z 2g
#

########## end pre-main ##########

########## VFIOPCIParse ##########

function VFIOPCI {

    # parameters #
    str_CPUbusID="00:00.0"
    str_thisPCIBusID=""
    str_prevPCIBusID=""
    str_VGAVendor=""
    #

    # lists #
    declare -a arr_PCIBusID=""
    declare -a arr_PCIHWID=""
    declare -a arr_PCIDriver=""
    declare -a arr_PCIIndex=""
    declare -a arr_PCIInfo=""
    declare -a arr_VGABusID=""
    declare -a arr_VGADriver=""
    declare -a arr_VGAHWID=""
    declare -a arr_VGAIndex=""
    declare -a arr_VGAVendorBusID=""
    declare -a arr_VGAVendorDriver=""
    declare -a arr_VGAVendorHWID=""
    declare -a arr_VGAVendorIndex=""
    #

    # create log file #
    str_dir_log="/var/log/"
    str_file_PCIInfo=$str_dir_log'lspci.log'
    str_file_PCIDriver=$str_dir_log'lspci-k.log'
    str_file_PCIHWID=$str_dir_log'lspci-n.log'
    lspci | grep ":00." > $str_file_PCIInfo
    lspci -k > $str_file_PCIDriver
    lspci -n | grep ":00." > $str_file_PCIHWID
    #

    # find external PCI device Index values, Bus ID, and drivers ##
    bool_parsePCI=false
    bool_parseVGA=false
    bool_parseVGAVendor=false
    declare -i int_index=0
    #

    ## parse list of PCI devices ##
    while read -r str_line; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        # parse external PCI devices #
        if [[ $bool_parsePCI == true ]]; then

            if [[ $str_line != *"Subsystem: "* && $str_line != *"Kernel driver in use: "* && $str_line != *"Kernel modules: "* ]]; then     # line includes PCI bus ID

                ((int_index++))                     # increment only if Bus ID is found
                arr_PCIInfo+=($str_line)            # add line to list
                str_thisPCIBusID=(${str_line:0:7})
                arr_PCIBusID+=($str_thisPCIBusID)   # add Bus ID index to list

                # match VGA device #
                if [[ $str_line == *"VGA"* ]]; then
            
                    arr_VGABusID+=($str_thisPCIBusID);
                    str_prevPCIBusID=($str_thisPCIBusID)
                    bool_parseVGA=true

                fi
                #

                # match VGA vendor device (Audio, USB3, etc.) #
                if [[ ${str_thisPCIBusID:0:6} == ${str_prevPCIBusID:0:6} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then

                    arr_VGAVendorBusID+=($str_thisPCIBusID);
                    bool_parseVGAVendor=true

                fi
                #

            fi

            # add to list only if driver is found #
            if [[ $str_line == *"Kernel driver in use: "* ]]; then      # line includes PCI driver

                declare -i int_offset=${#str_line}-22
                str_thisPCIDriver=${str_line:23:$int_offset}
                arr_PCIDriver+=($str_thisPCIDriver)
                arr_PCIIndex+=("$int_index")        

                # add to lists only if VGA device #
                if [[ $bool_parseVGA == true ]]; then

                    arr_VGAIndex+=("$int_index")
                    arr_VGADriver+=($str_thisPCIDriver);                # save for blacklists and Xorg

                fi
                #

                # add to list only if VGA vendor device #
                if [[ $bool_parseVGAVendor == true ]]; then

                    arr_VGAVendorIndex+=("$int_index");
                    arr_VGAVendorDriver+=("$str_thisPCIDriver")  

                fi
                #

                # reset booleans #
                bool_parseVGA=false
                bool_parseVGAVendor=false
                #

            fi
            #

        fi
        #

    done < $str_file_PCIDriver
    ##

    ## find external PCI Hardware IDs ##
    bool_parseVGAVendor=false
    declare -i int_index=0

    # parse list of PCI devices #
    while read -r str_line; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        # parse external PCI devices ##
        if [[ $bool_parsePCI == true ]]; then 

            str_thisPCIHWID=(${str_line:14:9})
            arr_PCIHWID+=($str_thisPCIHWID)

            # add to list only if VGA device
            if [[ ${arr_PCIInfo[$i]} == *"VGA"* ]]; then arr_VGAHWID+=($str_thisPCIHWID); fi

            # add to lists only if VGA vendor device
            if [[ ${str_thisPCIBusID:0:6} == ${str_prevPCIBusID:0:6} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then
        
            arr_VGAVendorHWID+=($str_thisPCIHWID);
            bool_parseVGAVendor=false

            fi

            ((i++))     # increment only if match is found

        fi
        #

    done < $str_file_PCIHWID

    # debug #
    function VFIOPCIDebug {

        echo -e "arr_PCIIndex:\t\t${#arr_PCIIndex[@]}i"
        for element in ${arr_PCIIndex[@]}; do
            echo -e "arr_PCIIndex:\t\t"$element
        done

        echo -e "arr_VGAIndex:\t\t${#arr_VGAIndex[@]}i"
        for element in ${arr_VGAIndex[@]}; do
            echo -e "arr_VGAIndex:\t\t"$element
        done

        echo -e "arr_VGAVendorIndex:\t${#arr_VGAVendorIndex[@]}i"
        for element in ${arr_VGAVendorIndex[@]}; do
            echo -e "arr_VGAVendorIndex:\t"$element
        done

        echo -e "arr_PCIBusID:\t\t${#arr_PCIBusID[@]}i"
        for element in ${arr_PCIBusID[@]}; do
            echo -e "PCIBusID:\t\t"$element
        done

        echo -e "arr_VGABusID:\t\t${#arr_VGABusID[@]}i"
        for element in ${arr_VGABusID[@]}; do
            echo -e "arr_VGABusID:\t\t"$element
        done

        echo -e "arr_VGAVendorBusID:\t${#arr_VGAVendorBusID[@]}i"
        for element in ${arr_VGAVendorBusID[@]}; do
            echo -e "arr_VGAVendorBusID:\t"$element
        done
    
    }

    # debug #
    VFIOPCIDebug
    #

}

########## end VFIOPCIParse ##########

########## HugePages ##########

function HugePages {

# parameters #
str_input=$2
str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
#

# prompt #
declare -i int_count=0      # reset counter
str_prompt="HugePages is a feature which statically allocates System Memory to pagefiles.\nVirtual machines can use HugePages to a peformance benefit.\nThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

if [[ $str_input == "N" ]]; then

    echo "Skipping HugePages..."
    return 0;
fi


if [[ -z $str_input || $str_input == "Y" ]]; then echo -e $str_prompt; fi

while [[ $str_input != "Y" && $str_input != "N" ]]; do

    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        str_input="N"                   # default selection
        
    else

        echo -en "Setup HugePages?\t[Y/n]: "
        read -r str_input
        str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

    fi

    case $str_input in

        "Y"||"H")
            echo "Continuing..."
            break;;

        "N")
            echo "Skipping..."
            return 0;;

        *)
            echo "Invalid input.";;

    esac
    ((int_count++))

done
#

# Hugepage size: validate input #
str_HugePageSize=$3
str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

declare -i int_count=0      # reset counter

while true; do
                 
    # attempt #
    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        str_HugePageSize="1G"           # default selection
        
    else

        echo -en "Enter Hugepage size and byte-size. [ 2M / 1G ]:\t"
        read -r str_HugePageSize
        str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

    fi
    #

    # check input #
    case $str_HugePageSize in

        "2M")
            break;;

        "1G")
            break;;

        *)
            echo "Invalid input.";;

    esac
    #

    ((int_count++))                     # inc counter

done
#

# Hugepage sum: validate input #
int_HugePageNum=$4
declare -i int_count=0      # reset counter

while true; do

    # attempt #
    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        int_HugePageNum=$int_HugePageMax        # default selection
        
    else

        # Hugepage Size #
        if [[ $str_HugePageSize == "2M" ]]; then

            str_prefixMem="M"
            declare -i int_HugePageK=2048       # Hugepage size
            declare -i int_HugePageMin=2        # min HugePages

        fi

        if [[ $str_HugePageSize == "1G" ]]; then

            str_prefixMem="G"
            declare -i int_HugePageK=1048576    # Hugepage size
            declare -i int_HugePageMin=1        # min HugePages

        fi

        declare -i int_HostMemMinK=4194304                              # min host RAM in KiB
        declare -i int_HugePageMemMax=$int_HostMemMaxK-$int_HostMemMinK
        declare -i int_HugePageMax=$int_HugePageMemMax/$int_HugePageK   # max HugePages

        echo -en "Enter number of HugePages ( num * $str_HugePageSize ). [ $int_HugePageMin to $int_HugePageMax pages ] : "
        read -r int_HugePageNum
        #

    fi
    #

    # check input #
    if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then

        echo "Invalid input."
        ((int_count++));     # inc counter

    else
    
        echo -e "Continuing..."
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"
        break
        
    fi
    #

done
#

}

########## end HugePages ##########

########## Prompts ##########

# parameters #
str_input=$1
#

# prompt #
declare -i int_count=0      # reset counter
str_prompt="Setup VFIO by 'Multi-Boot' or Statically.\nMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\nStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\nMulti-boot is the more flexible choice."

if [[ -z $str_input ]]; then echo -e $str_prompt; fi

while [[ $str_input != "B" && $str_input != "S" ]]; do

    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        str_input="B"                   # default selection
        
    else

        echo -en "Setup VFIO?\t[ Multi-(B)oot / (S)tatic ]: "
        read -r str_input
        str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

    fi

    case $str_input in

        "B")
            echo "Continuing with Multi-Boot setup..."
            HugePages $2 $3 $4
            VFIOParse
            MultiBootSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
            StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
            break;;

        "S")
            echo "Continuing with Static setup..."
            HugePages $2 $3 $4
            StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
            break;;

        *)
            echo "Invalid input.";;

    esac
    ((int_count++))

done
#

########## end Prompts ##########

########## MultiBootSetup ##########

function MultiBootSetup {

    ## parameters ##
    str_Distribution=`lsb_release -a | grep "Distributor ID: "* | cut -d ":" -f 2`  # Linux distro name
    str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` "                 # incomplete, append Kernel image rev.
    declare -a arr_rootKernel+=`find /boot/vmli*`                                   # list of Kernels
    
    # root Dev #
    str_rootDiskInfo=`df -hT | grep /$`
    str_rootDev=${str_rootDiskInfo:5:4}     # example "sda1"
    #

    # root UUID #
    str_rootUUID=`sudo blkid | grep $str_rootDev | cut -d '"' -f 2`
    #

    # custom GRUB #
    str_file1="/etc/grub.d/proxifiedScripts/custom"
    if [[ ! -z $str_file1"_old" ]]; then

        cp $str_file1 $str_file1"_old"
        echo -e"#!/bin/sh
exec tail -n +3 /home/user/test-findpci.bash
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above." > $str_file1

    fi
    #
    ##

    # find UUID #
    for element in ${arr_str_rootBlkInfo[@]}; do

        # root UUID match #
        if [[ $bool_nextElement == true ]]; then str_rootUUID=$element; break
        else bool_nextElement=false; fi
        #

        if [[ $element == *$str_rootDev* ]]; then bool_nextElement=true; fi     # root dev match

    done
    #

    # create individual VGA device GRUB options #
    for int_VGAIndex in $arr_VGAIndex; do
        
        str_thisVGABusID="${arr_VGABusID[$int_VGAIndex]}"
        str_thisVGADriver="${arr_VGADriver[$int_VGAIndex]}"
        str_thisVGAHWID="${arr_VGAHWID[$int_VGAIndex]}"

        #echo -e "GRUB:\int_VGAIndex: \"$int_VGAIndex\""
        #echo -e "GRUB:\str_thisVGABusID: \"$str_thisVGABusID\""
        #echo -e "GRUB:\str_thisVGADriver: \"$str_thisVGADriver\""
        #echo -e "GRUB:\str_thisVGAHWID: \"$str_thisVGAHWID\""

        # add to list, separate by comma #
        for (( int_index=0; int_index<${#arr_PCIIndex[@]}; int_index++ )); do

            int_PCIIndex=${arr_PCIIndex[int_index]}             # save current index
            str_thisPCIDriver=${arr_PCIDriver[$int_PCIIndex]}

            # add index #
            if [[ $str_thisPCIDriver != $str_thisVGADriver ]]; then str_listPCIDriver+="${arr_PCIBusID[$int_PCIIndex]}," ;fi

            if [[ $int_PCIIndex != $int_VGAIndex ]]; then
            
                str_listPCIBusID+="${arr_PCIBusID[$int_PCIIndex]},"
                str_listPCIHWID+="${arr_PCIHWID[$int_PCIIndex]},"
                
            fi
            #

            # add last index #
            if [[ $str_thisPCIDriver != $str_thisVGADriver && $int_index == ${#arr_PCIIndex[@]}-1 ]]; then str_listPCIDriver+="${arr_PCIBusID[$int_PCIIndex]}"; fi

            if [[ $int_PCIIndex != $int_VGAIndex && $int_index == ${#arr_PCIIndex[@]}-1 ]]; then
            
                str_listPCIBusID+="${arr_PCIBusID[$int_PCIIndex]}"
                str_listPCIHWID+="${arr_PCIHWID[$int_PCIIndex]}"
            
            fi
            #

            # GRUB command line #
            str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$arr_VGADriver,$str_arr_PCIDriver vfio_pci.ids=$arr_VGAHWID,$str_arr_PCIHWID"
            #

            # parse Kernels #
            for str_rootKernel in arr_rootKernel; do

                # set Kernel #
                declare -i int_rootKernel=${#str_rootKernel}-14
                str_rootKernel=${str_rootKernel:14:int_rootKernel}
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle+="$str_rootKernel (Xorg: Bus=$str_thisVGABusID, Drv=$str_thisVGADriver)'"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    insmod gzio
    set root='/dev/$str_rootDev'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUBline
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
    echo    'Xorg: $str_thisVGABusID: $str_thisVGADriver'"
            )

                echo -e "\n${arr_file_customGRUB[@]}" > $str_file1      # write to file

            done   
            #

        done
        #

    done
    #

}

########## end MultiBootSetup ##########

########## StaticSetup ##########

# NOTES:
# make sure StaticSetup checks if MultiBootSetup ran. If true, create Static configs with only non-VGA and non-VGA-vendor devices.
# otherwise, ask user which VGA device to leave as Host VGA device

function StaticSetup {

    # files #
    str_file1="/etc/default/grub"
    str_file2="/etc/initramfs-tools/modules"
    str_file3="/etc/modules"
    str_file4="/etc/modprobe.d/vfio.conf"
    #

    # GRUB #
    str_GRUB="GRUB_CMDLINE_DEFAULT=\" acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_arr_PCIDriver vfio_pci.ids=$str_arr_PCIHWID\""
    echo -e "#\n${str_GRUB}" >> $str_file1
    #

    # initramfs-tools #
    declare -a arr_file2=(
"# List of modules that you want to include in your initramfs.
# They will be loaded at boot time in the order below.
#
# Syntax:  module_name [args ...]
#
# You must run update-initramfs(8) to effect this change.
#
# Examples:
#
# raid1
# sd_mod
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.

# Soft dependencies and PCI kernel drivers:
$str_PCIDriver_softdep

vfio
vfio_iommu_type1
vfio_virqfd

# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIHWID
vfio_pci ids=$str_arr_PCIHWID
vfio_pci"
)
    echo ${arr_file2[@]} > $str_file2
    #

    # modules #
    declare -a arr_file3=(
"# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with \"#\" are ignored.
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
#
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
kvm
kvm_intel
apm power_off=1

# In terminal, execute \"lspci -nnk\".

# GRUB kernel parameters:
vfio_pci ids=$str_arr_PCIHWID"
)
    echo ${arr_file3[@]} > $str_file3
    #

    # modprobe.d/blacklists #
    for str_PCIDriver in $arr_PCIDriver[@]; do
        echo "blacklist $str_PCIDriver" > "/etc/modprobe.d/$str_PCIDriver.conf"
    done
    #

    # modprobe.d/vfio.conf #
    declare -a arr_file4=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCIDriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIHWID")
    echo ${arr_file4[@]} > $str_file4
    #

}

########## end StaticSetup ##########

########## Xorg ##########

########## end Xorg ##########

########## EvDev ##########

function EvDev {

    # parameters #
    str_input=$5
    str_file1="/etc/libvirt/qemu.conf"
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="Setup EvDev?\nEvDev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\nEvDev is recommended for setups without an external KVM switch and multiple USB controllers.\nNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

    if [[ -z $str_input ]]; then echo -e $str_prompt; fi

    while [[ $str_input != "Y" && $str_input != "Z" && $str_input != "N" ]]; do

    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        str_input="Y"                   # default selection
        
    else

        echo -en "Setup EvDev?\t[ Y/n ]: "
        read -r str_input
        str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

    fi

    case $str_input in

        "Y"||"E")
            echo "Continuing with EvDev setup..."
            break;;

        "N")
            echo "Skipping EvDev setup..."
            return 0;;

        *)
            echo "Invalid input.";;

    esac
    ((int_count++))

    done
    #

    # find first normal user
    str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1`
    #

    # add to group
    declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)   # find all normal users
    for str_User in $arr_User; do sudo adduser $str_User libvirt; done      # add each normal user to libvirt group
    #

    # list of input devices
    declare -a arr_InputDeviceID=(`ls /dev/input/by-id`)
    #declare -a arr_InputDeviceInfo=(`ls -al /dev/input/by-id`)
    #

    # file changes #
    str_file_QEMU=$("
#
user = "$str_UID1000"
group = "user"
#
#
hugetlbfs_mount = "/dev/hugepages"
#
nvram = [
   "/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd",
   "/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd",
   "/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd",
   "/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd"
]
cgroup_device_acl = [
")

    for str_InputDeviceID in $arr_InputDeviceID; do $str_file_QEMU+=$(""/dev/input/by-id/$str_InputDeviceID""); done

    str_file_QEMU+=$("    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm",
    "/dev/rtc","/dev/hpet"
]")
    #

    # backup config file #
    if [[ ! -z $str_file1"_old" ]]; then cp $str_file1 $str_file1"_old"
    else cp $str_file1 $str_file1"_old" $str_file1; fi
    #

    # write to file #
    echo $str_file_QEMU > $str_file1
    #

}

########## end EvDev ##########

########## ZRAM ##########

function ZRAM {

    # parameters #
    str_input=$6
    str_file1="/etc/default/zramswap"
    str_file2="/etc/default/zram-swap"
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="Setup ZRAM? ZRAM allocates RAM as a compressed swapfile. The default compression method \"lz4\", at a ratio of 2:1, offers the highest performance."

    if [[ -z $str_input ]]; then echo -e $str_prompt; fi

    while [[ $str_input != "Y" && $str_input != "Z" && $str_input != "N" ]]; do

    if [[ $int_count -ge 3 ]]; then

        echo "Exceeded max attempts."
        str_input="Y"                   # default selection
        
    else

        echo -en "Setup ZRAM?\t[ Y/n ]: "
        read -r str_input
        str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

    fi

    case $str_input in

        "Y"||"Z")
            echo "Continuing with ZRAM setup..."
            break;;

        "N")
            echo "Skipping ZRAM setup..."
            return 0;;

        *)
            echo "Invalid input.";;

    esac
    ((int_count++))

    done
    #

    # parameters #
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    str_GitHub_Repo="FoundObjects/zram-swap"
    #

    # check for zram-utils #
    if [[ ! -z $str_file1 ]]; then

        apt install -y git zram-utils
        systemctl stop zramswap
        systemctl disable zramswap

    fi
    #

    # check for local repo #
    if [[ ! -z "/root/git/$str_GitHub_Repo" ]]; then
    
        mkdir /root/git
        mkdir /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        git clone https://www.github.com/$str_GitHub_Repo

    else

        cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`    
        git pull https://www.github.com/$str_GitHub_Repo
    
    fi
    #

    # check for zram-swap #
    if [[ ! -z $str_file2 ]]; then sh /root/git/$str_GitHub_Repo/install.sh fi
    #

    # disable ZRAM swap #
    if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then sudo swapoff /dev/zram*; fi
    #
    
    # backup config file #
    if [[ ! -z $str_file2"_old" ]]; then cp $str_file2 $str_file2"_old"; fi
    #

    # find HugePage size #
    if [[ $str_HugePageSize == "2M" ]]; then declare -i int_HugePageSizeK=2048; fi

    if [[ $str_HugePageSize == "1G" ]]; then declare -i int_HugePageSizeK=1048576; fi
    #

    # find free memory #
    declare -i int_HostMemFreeG=($int_HostMemMaxK-($int_HugePageNum*$int_HugePageSizeK))/1048576
    declare -i int_ZRAM_SizeG=0
    #

    # setup ZRAM #
    if [[ $int_HostMemFreeG -le 8 ]]; then $int_ZRAM_SizeG=$int_HostMemFreeG/2
    else $int_ZRAM_SizeG=4; fi
    str_input_ZRAM="_zram_fixedsize=\"`$int_ZRAM_SizeG`G\""
    #

    # file 3
    declare -a arr_file_ZRAM="# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)
# default: lz4
_zram_algorithm="lz4"

# portion of system ram to use as zram swap (expression: "1/2", "2/3", "0.5", etc)
# default: "1/2"
#_zram_fraction="1/2"

# setting _zram_swap_debugging to any non-zero value enables debugging
# default: undefined
#_zram_swap_debugging="beep boop"

# expected compression factor; set this by hand if your compression results are
# drastically different from the estimates below
#
# Note: These are the defaults coded into /usr/local/sbin/zram-swap.sh; don't alter
#       these values, use the override variable '_comp_factor' below.
#
# defaults if otherwise unset:
#       lzo*|zstd)  _comp_factor="3"   ;; # expect 3:1 compression from lzo*, zstd
#       lz4)        _comp_factor="2.5" ;; # expect 2.5:1 compression from lz4
#       *)          _comp_factor="2"   ;; # default to 2:1 for everything else
#
#_comp_factor="2.5"

# if set skip device size calculation and create a fixed-size swap device
# (size, in MiB/GiB, eg: "250M" "500M" "1.5G" "2G" "6G" etc.)
#
# Note: this is the swap device size before compression, real memory use will
#       depend on compression results, a 2-3x reduction is typical
#
$str_input_ZRAM

# vim:ft=sh:ts=2:sts=2:sw=2:et:"
    #

    # write to file #
    rm $str_file2
    for str_line in ${arr_file_ZRAM[@]}; do
        echo $str_line >> $str_file2
    done
    #

}

########## end ZRAM ##########

########## main ##########

#VFIOPCIParse
Prompts $1 $2 $3 $4
#Xorg
#EvDev $5
#ZRAM $6

## reset IFS ##
IFS=$SAVEIFS   # Restore original IFS
##

exit 0

########## end main ##########
