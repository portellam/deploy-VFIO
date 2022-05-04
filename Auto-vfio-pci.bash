#!/bin/bash

## METHODS start ##

function 01_FindPCI {
    
    echo "FindPCI: Start."

    # CREATE LOG FILE #
    str_dir="/var/log/"
    str_file_1=$str_file'lspci_n.log'
    str_file_2=$str_file'lspci.log'
    str_file_3=$str_file'lspci_k.log'
    lspci -n > $str_file_1
    lspci -k > $str_file_2
    #

    ## BOOLEANS ##
    bool_beginParsePCI=false
    bool_beginParseVGA=false
    bool_thisVGA=false
    #

    # COUNTER #
    declare -i int_count=1
    #

    # PCI #
    str_firstPCIbusID="1:00.0"
    str_thisPCIbusID=""
    str_thisPCIdriver=""
    str_thisPCIhwID=""
    str_thisPCItype=""
    str_VGAbusID=""
    str_VGAdriver=""
    declare -a arr_PCIbusID
    declare -a arr_PCIdriver
    declare -a arr_PCIhwID
    declare -a arr_VGAindex
    #

    # AUTO VFIO PCI SETUP TO-DO:
    # first loop: cycle list, save all PCI bus IDs to an array.
    # second loop: assume first-run for new system (no devices added to VFIO-PCI): cycle list, save all PCI drivers to an array (same size as before).
    # final loop: cycle list, save all PCI HW IDs to an array (same size as before).
    # next function: update config files (/etc/modules, /etc/default/grub)

    # XORG VFIO PCI SETUP TO-DO:
    # *run as a systemd service
    # first loop: cycle list, save all PCI bus IDs to an array, and save index of VGA devices to an array.
    # final loop: cycle list, stop at first VGA device without VFIO-PCI driver; find the index of the array with all PCI devices with the index of the array of VGA devices; save the VGA bus ID and driver.
    # next function: update xorg conf file

    # FILE_1 #
    # PARSE FILE, SAVE PCI BUS ID AND PCI HW ID TO ARRAYS
    while read str_line_1; do
        
        str_thisPCIbusID=${str_line_1:1:6}
        echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""

        # START READ FROM FIRST EXTERNAL PCI
        if [[ $str_thisPCIbusID == $str_firstPCIbusID ]]; then
                
            bool_beginParsePCI=true

        fi
        
        # SAVE PCI HARDWARE ID
        if [[ $bool_beginParsePCI == true ]]; then

            arr_PCIbusID+=("$str_thisPCIbusID")
            echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""
            str_thisPCIhwID=$( echo ${str_line_1:14:9} )
            echo "PCI: str_thisPCIhwID: \"$str_thisPCIhwID\""
            arr_PCIhwID+=("$str_thisPCIhwID")
            
        fi

    done < $str_file_1
    # FILE 1 END #

    # FILE 2 #
    # PARSE FILE, SAVE EACH DRIVER FOR VFIO SETUP, AND CHECK IF INDEXED VGA DEVICE IS NOT GRABBED BY VFIO-PCI DRIVER AND SAVE VGA DEVICE PCI BUS ID, HW ID, AND DRIVER FOR XORG SETUP
    while read str_line_2; do

        str_thisPCIbusID=${str_line_2:1:6}
        echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""
        int_len_str_line_3=${#str_line_3}-22
        str_thisPCIdriver=${str_line_3:22:$int_len_str_line_3}
        echo "PCI: str_thisPCIdriver: \"$str_thisPCIdriver\""

        # START READ FROM FIRST EXTERNAL PCI
        if [[ $str_thisPCIbusID == $str_firstPCIbusID && $str_line_2 != *"Kernel driver in use: "* && $str_line_2 != *"Subsystem: "* && $str_line_2 != *"Kernel modules: "* ]]; then
            
            if [[ $str_line_2 == *"VGA compatible controller"* ]]; then

                bool_beginParseVGA=true

            else

                bool_beginParseVGA=false
            
            fi

            bool_beginParsePCI=true

        fi

        # VALIDATE STRING FOR PCI DRIVER
        if [[ $bool_beginParsePCI == true && $str_thisPCIdriver != "vfio-pci" && $str_line_2 == *"Kernel driver in use: "* ]]; then
            
            if [[ $bool_beginParseVGA == true ]]; then

                arr_VGAindex+="$int_count"
                bool_beginParseVGA=false

            else

                arr_PCIdriver+=("$str_thisPCIdriver")

            fi
            
            bool_beginParsePCI=false

        fi

        echo "PCI: int_count:\"$int_count\""
        int_count=$int_count+1
        echo "PCI: int_count:\"$int_count\""

    done < $str_file_2
    # FILE 2 END #
            
    # CLEAR LOG FILES
    rm $str_file_1 $str_file_2
        
    echo "FindPCI: End."
    
}

function 02_VFIO {

    echo "VFIO: Start."

    # PARAMETERS #
    declare -a arr_PCIdriver=""
    for (( int_index=0; int_index<$[${#arr_PCIdriver[@]}]; int_index++ )); do

        element=${arr_PCIdriver[$int_index]}
        str_PCIdriver_softdep+=("#softdep $element pre: vfio vfio-pci" "$element")
        if [[ $int_index -eq "${#arr_PCIdriver[@]}-1" ]]; then
        
            str_arr_PCIhwID+=("$element")
        
        else

            str_arr_PCIhwID+=("$element,")

        fi

    done
    #
    str_arr_PCIhwID=""
    for (( int_index=0; int_index<$[${#arr_PCIhwID[@]}]; int_index++ )); do

        element=${arr_PCIhwID[$int_index]}

        if [[ $int_index -eq "${#arr_PCIhwID[@]}-1" ]]; then
        
            str_arr_PCIhwID+=("$element")
        
        else

            str_arr_PCIhwID+=("$element,")

        fi

    done
    #
    str_dir_1="/etc/grub.d/"
    str_dir_2="/etc/modprobe.d/"
    str_file_1="/etc/default/grub"
    str_file_2="/etc/modules"
    str_file_3="/etc/initramfs-tools/modules"
    str_file_4="/etc/modprobe.d/vfio.conf"
    #

    # GRUB.D #

    # active kernel #
    str_rootKernel=`uname -r`
    echo "FindRoot: str_rootKernel: \"$str_rootKernel\""

    # root dev info #
    str_rootDiskInfo=`df -hT | grep /$`
    str_rootDev=${str_rootDiskInfo:5:4}   # example "sda1"
    echo "FindRoot: str_rootDev: \"$str_rootDev\""
    #

    # root UUID #
    str_rootUUID=""
    declare -a arr_str_rootBlkInfo+=( `lsblk -o NAME,UUID` )

    ## find UUID
    for element in ${arr_str_rootBlkInfo[@]}; do

        echo "FindRoot: element: \"$element\""

        # root UUID match
        if [[ $bool_nextElement == true ]]; then

            str_rootUUID=$element
            #echo "FindRoot: str_rootUUID: \"$str_rootUUID\""
            break

        else bool_nextElement=false; fi

        # root dev match
        if [[ $element == *$str_rootDev* ]]; then bool_nextElement=true; fi        

    done
    #

    for $element in $arr_int_indexOfVGA[@]; do

        ## TO-DO: have an array of ALL PCI hw ID, and and array of ALL drivers (with VGA), and have two arrays without VGA
        # to make multiple grub boot menus for different vga devices as host graphics :)

        #str_thisVGAbusID=
        str_GRUB="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 default_hugepagesz=1G hugepagesz=1G hugepages=24 modprobe.blacklist=$str_thisVGAdriver,$str_arr_PCIdriver vfio_pci.ids=$str_thisVGAbusID,$str_arr_PCIhwID"
        declare -a arr_dir_1_file=(
"menuentry '$element' {
    insmod gzio
    set root='/dev/$str_rootDev'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID ro $str_GRUB
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-")

        #echo ${arr_file_1[@]} > $str_file_1
    # GRUB.D end #

    # MODPROBE.D/BLACKLIST #
    for $element in $arr_PCIdriver[@]; do

        echo "blacklist $element" > $str_dir_2$element'.conf'

    done
    #

    # GRUB ########
    declare -a arr_file_1=("
    #GRUB_CMDLINE_LINUX_DEFAULT=\"acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 default_hugepagesz=1G hugepagesz=1G hugepages=24 modprobe.blacklist=${arr_PCIdriver[@]} vfio_pci.ids=\"")
    #

    # MODULES #
    declare -a arr_file_2=(
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
vfio_pci ids=$str_arr_PCIhwID"
)
    #echo ${arr_file_2[@]} > $str_file_2
    #

    # INITRAMFS-TOOLS/MODULES #
    declare -a arr_file_3=(
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
$str_PCIdriver_softdep

vfio
vfio_iommu_type1
vfio_virqfd

# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIhwID
vfio_pci ids=$str_arr_PCIhwID
vfio_pci"
)
    #echo ${arr_file_3[@]} > $str_file_3
    #

    # MODPROBE.D/VFIO #
    declare -a arr_file_4=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCIdriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIhwID")
    #echo ${arr_file_4[@]} > $str_file_4
    #

    echo "VFIO: End."

}

## METHODS end ##

# NOTES:

# divide large functions into smaller ones, note dependencies and order accordingly.
# VFIO should be Boot-based VFIO and Permanent VFIO, and/or Combined ( example: GRUB, and MODULES+MODPROBE.D )
# reduce repeated functions/work

## MAIN start ##

echo "MAIN: Start."

# METHODS #
01_FindPCI
#02_Modules
#03_GRUB

echo "MAIN: End."

## MAIN end ##

exit 0
