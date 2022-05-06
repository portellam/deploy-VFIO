#!/bin/bash

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# methods start #

function 01_lspci {

    #echo -e "lspci:\t\tStart."

    # parameters #
    str_CPUbusID="00:00.0"
    str_thisPCIBusID=""
    str_prevPCIBusID=""
    str_VGAVendor=""
    #

    # outputs #
    declare -a arr_PCIBusID    
    declare -a arr_PCIHWID
    declare -a arr_PCIDriver
    declare -a arr_PCIIndex
    declare -a arr_PCIInfo
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    declare -a arr_VGAHWID
    declare -a arr_VGAIndex
    declare -a arr_VGAVendorBusID
    declare -a arr_VGAVendorDriver
    declare -a arr_VGAVendorHWID
    declare -a arr_VGAVendorIndex
    #

    # create log file #
    #str_dir="/var/log/"
    #str_dir="/dev/tmp/"
    cd ~/
    str_dir="./"
    str_file_arr_PCIInfo=$str_dir'lspci.log'
    str_file_arr_PCIDriver=$str_dir'lspci-k.log'
    str_file_arr_PCIHWID=$str_dir'lspci-n.log'
    lspci | grep ":00." > $str_file_arr_PCIInfo
    lspci -k > $str_file_arr_PCIDriver
    lspci -n | grep ":00." > $str_file_arr_PCIHWID
    #

    # find external PCI device Index values, Bus ID, and drivers #
    
    bool_parsePCI=false
    bool_parseVGA=false
    bool_parseVGAVendor=false
    declare -i int_index=0

    # parse list of PCI devices
    while read -r str_line; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        if [[ $bool_parsePCI == true ]]; then

            # line includes PCI bus ID
            if [[ $str_line != *"Subsystem: "* && $str_line != *"Kernel driver in use: "* && $str_line != *"Kernel modules: "* ]]; then
            
                ((int_index++))                     # increment only if Bus ID is found
                arr_PCIInfo+=($str_line)            # add line to list
                str_thisPCIBusID=(${str_line:0:7})
                arr_PCIBusID+=($str_thisPCIBusID)   # add Bus ID index to list

                # match VGA device
                if [[ $str_line == *"VGA"* ]]; then

                    arr_VGABusID+=($str_thisPCIBusID);
                    str_prevPCIBusID=($str_thisPCIBusID)
                    bool_parseVGA=true

                fi

                # match VGA vendor device (Audio, USB3, etc.)
                if [[ ${str_thisPCIBusID:0:6} == ${str_prevPCIBusID:0:6} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then
                
                    arr_VGAVendorBusID+=($str_thisPCIBusID);
                    bool_parseVGAVendor=true

                fi

            fi
            
            # line includes PCI driver
            # add to list only if driver is found
            if [[ $str_line == *"Kernel driver in use: "* ]]; then 
            
                declare -i int_offset=${#str_line}-22
                str_thisPCIDriver=${str_line:23:$int_offset}
                arr_PCIDriver+=($str_thisPCIDriver)
                arr_PCIIndex+=("$int_index")                

                # add to lists only if VGA device
                if [[ $bool_parseVGA == true ]]; then

                    arr_VGAIndex+=("$int_index")
                    arr_VGADriver+=($str_thisPCIDriver);    # save for blacklists and Xorg

                fi

                # add to list only if VGA vendor device  
                if [[ $bool_parseVGAVendor == true ]]; then
                
                    arr_VGAVendorIndex+=("$int_index");
                    arr_VGAVendorDriver+=("$str_thisPCIDriver")    
                    
                fi

                bool_parseVGA=false
                bool_parseVGAVendor=false

            fi
        fi

    done < $str_file_arr_PCIDriver
    #

    # find external PCI Hardware IDs#
    bool_parseVGAVendor=false
    declare -i int_index=0

    # parse list of PCI devices
    while read -r str_line; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

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

    done < $str_file_arr_PCIHWID
    #

    ##
    function VFIO_PCI_DEBUG {
    
        ## debug ##
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
    ##

    ## run debug ##
    #VFIO_PCI_DEBUG
    ##

    # remove log files #
    rm $str_file_arr_PCIInfo $str_file_arr_PCIDriver $str_file_arr_PCIHWID
    #

    #echo -e "lspci:\t\tEnd."

}

# NOTE: test!
function 02_VFIO {

    echo -e "\nVFIO:\t\tStart."

    # dependencies #
    # bool_RAM #
    # int_count #
    # int_hugePageSizeG #
    # int_hugePageSum #
    #

    # arameters #
    bool_GRUB_VGA=false
    declare -i int_count=0
    #

    # prompt #
    # ask user to enable/disable hugepages
    VFIO_RAM
    #

    # outputs #
    # array of PCI drivers excluding VGA drivers
    declare -a arr_PCIDriver=""

    # array of PCI hw IDs excluding VGA hardware IDs
    str_arr_PCIHWID=""

    # add PCI driver and hardware IDs to strings for VFIO
    for (( int_index=0; int_index<$[${#arr_PCIDriver[@]}]; int_index++ )); do

        element=${arr_PCIDriver[$int_index]}

        for element_2 in $arr_VGAindex; do

            if [[ $element_2 != $int_index ]]; then

                str_PCIDriver_softdep+=("#softdep $element pre: vfio vfio-pci" "$element")

                if [[ $int_index -eq "${#arr_PCIDriver[@]}-1" ]]; then str_arr_PCIHWID+=("$element");
                else str_arr_PCIHWID+=("$element,"); fi

            fi

        done

    done
    #

    ## prompt ##
    echo -e "VFIO:\t\tYou may setup VFIO 'persistently' or through GRUB.\nPersistent includes modifying '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\nGRUB includes multiple GRUB options of omitted, single VGA devices (example: omit a given VGA device to boot Xorg from)."

    while true; do

        # after three tries, continue with default selection
        if [[ $int_count -ge 3 ]]; then

            echo -e "VFIO:\t\tExceeded max attempts."
            # default selection
            str_input="B"
            # reset counter
            int_count=0

        else

            echo -en "VFIO:\t\t['ETC'/'GRUB'/'both']: "
            read -r str_input
            # string to upper
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`
        fi        

        # switch #
        case $str_input in

            "GRUB")
                # modify GRUB boot options only
                VFIO_GRUB
                break;;

            "ETC")
                # ask user which VGA devices to passthrough OR which to avoid
                # modify modules and initramfs-tools only
                VFIO_ETC
                break;;

            "BOTH")

                # execute GRUB and VFIO, save VGA devices for GRUB options
                VFIO_GRUB
                VFIO_ETC
                break;;

        *)
            echo -e "VFIO:\t\tInvalid input.";;

        esac

        # counter
        int_count=$int_count+1  

    done
    ##

    echo -e "VFIO:\t\tEnd."

}

# NOTE: test!
function VFIO_ETC {

    echo -e "\nVFIO_ETC:\tStart."

    # dependencies #
    # arr_PCIDriver
    # str_arr_PCIHWID
    # str_GRUBlineRAM
    # arr_PCIBusID    
    # arr_PCIHWID
    # arr_PCIDriver
    # arr_PCIIndex
    # arr_PCIInfo
    # arr_VGABusID
    # arr_VGADriver
    # arr_VGAHWID
    # arr_VGAIndex
    # arr_VGAVendorBusID
    # arr_VGAVendorDriver
    # arr_VGAVendorHWID
    # arr_VGAVendorIndex
    #

    # directories #
    #str_dir_1="/etc/modprobe.d/"
    cd ~/
    str_dir_1="./"
    #

    # files #
    #str_file_1="/etc/default/grub"
    #str_file_2="/etc/initramfs-tools/modules"
    #str_file_3="/etc/modules"
    #str_file_4="/etc/modprobe.d/vfio.conf"
    str_file_1="0_grub.log"
    str_file_2="0_initramfs.log"
    str_file_3="0_modules.log"
    str_file_4="0_vfio.log"
    #

    # GRUB #
    str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$str_arr_PCIDriver vfio_pci.ids=$str_arr_PCIHWID"
    echo -e \n"#"\n${str_GRUBline} >> $str_file_1
    #

    # initramfs-tools #
    declare -a str_file_2=(
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
    echo ${str_file_2[@]} > $str_file_2
    #

    # modules #
    declare -a arr_file_3=(
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
    echo ${arr_file_3[@]} > $str_file_3
    #

    # modprobe.d/blacklists #
    for $element in $arr_PCIDriver[@]; do
        echo "blacklist $element" > $str_dir_1$element'.conf'
    done
    #

    # modprobe.d/vfio.conf #
    declare -a arr_file_4=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCIDriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIHWID")
    echo ${str_file_4[@]} > $str_file_4
    #

    echo -e "VFIO_ETC:\tEnd."

}

# NOTE: test!
function VFIO_GRUB {

    echo -e "\nVFIO_GRUB:\tStart."

    # dependencies #
    # str_GRUBlineRAM #
    #

    # grub menu entry
    str_GRUBtitle="Debian "`uname -o`", with"`uname -r`
    #

    # set directory
    str_dir_1="/etc/grub.d/"
    #

    # active kernel #
    str_rootKernel=`uname -r`
    #

    # root dev info #
    str_rootDiskInfo=`df -hT | grep /$`
    str_rootDev=${str_rootDiskInfo:5:4}   # example "sda1"
    #

    # root UUID #
    str_rootUUID=""
    declare -a arr_str_rootBlkInfo+=( `lsblk -o NAME,UUID` )
    #

    # find UUID #
    for element in ${arr_str_rootBlkInfo[@]}; do

        # root UUID match
        if [[ $bool_nextElement == true ]]; then str_rootUUID=$element; break
        else bool_nextElement=false; fi

        # root dev match
        if [[ $element == *$str_rootDev* ]]; then bool_nextElement=true; fi     

    done
    #

    # create individual VGA device GRUB options
    for element in $arr_VGAIndex; do

        # save current VGA bus ID
        str_VGABusID=${arr_PCIbusID[$element]}

        # temporarily save VGA drivers and hardware IDs of all VGA devices except the current VGA device
        for element_2 in $arr_VGAIndex; do

            if [[ $element_2 != $element ]]; then

                declare -a arr_VGADriver+=${arr_PCIDriver[$element]}
                declare -a arr_VGAHWID+=${arr_PCIHWID[$element]}

            fi

        done

        # GRUB command line
        str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$arr_VGADriver,$str_arr_PCIDriver vfio_pci.ids=$arr_VGAHWID,$str_arr_PCIHWID"

        str_VGAdev=`lspci | grep $str_VGABusID`

        # GRUB custom menu
        declare -a arr_dir_1_file=(
"menuentry '$str_GRUBtitle (Xorg: $str_VGAdev)' {
    insmod gzio
    set root='/dev/$str_rootDev'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUBline
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
    echo    'Xorg: $str_VGAdev"
)
        #

        # write to file
        echo ${arr_file_1[@]} > $str_dir_1'40_'$str_VGABusID

    done

    echo -e "VFIO_GRUB:\tEnd."

}

# NOTE: works!
function VFIO_RAM {

    #echo -e "\nVFIO_RAM:\tStart."

    # outputs #
    str_GRUBlineRAM=""
    #

    # parameters #
    bool_RAM=false
    declare -i int_count=0
    declare -i int_hugePageSizeG=1
    declare -i int_hugePageSum=1
    #

    echo -e "VFIO_RAM:\tDo you wish to enable Hugepages?\nHugepages is a feature which statically allocates system RAM to page-files, which may be used by Virtual machines.\nFor example, performance benefits include reduced/minimal memory latency."

    # after three tries, continue with default selection
    while true; do

        if [[ $int_count -ge 3 ]]; then

            echo -e "VFIO_RAM:\tExceeded max attempts."

            # default selection
            str_input="N"
            echo -e "VFIO_RAM:\tstr_input: \"$str_input\""

        else

            echo -en "VFIO_RAM:\t[Y/n]: "
            read -r str_input
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

            # prompt
            case $str_input in

                "Y")

                echo -e "VFIO_RAM:\tCreating Hugepages."
                bool_RAM=true
                break;;

                "N")

                echo -e "VFIO_RAM:\tSkipping."
                break;;

                *)
                echo -e "VFIO_RAM:\tInvalid input.";;

            esac

            # counter
            echo -e "VFIO_RAM:\tint_count: \"$int_count\""
            int_count=$int_count+1    
            echo -e "VFIO_RAM:\tint_count: \"$int_count\""

        fi

    done

    # default selection
    int_hugePageSum=1

    # find total RAM #
    str_sumMemK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`
    declare -i int_sumMemK=$str_sumMemK
    declare -i int_maxMemG=($int_sumMemK/1024/1024)
    int_maxMemG=($int_maxMemG-4)
    #

    # skip if max RAM is too little #
    if [[ $int_maxMemG -le 1 ]]; then
        
        echo -e "VFIO_RAM:\tSystem RAM is too limited to create hugepages. Skipping."
        bool_RAM=false    
            
    fi
    #

    # warn if max RAM may be too little # 
    if [[ $int_maxMemG -le 4 && $int_maxMemG -gt 1 ]]; then

        echo -e "VFIO_RAM:\tSystem RAM may be too limited to create hugepages. Continue?"

        while true; do

            if [[ $int_count -ge 3 ]]; then

                echo -e "VFIO_RAM:\tExceeded max attempts."

                # default selection
                str_input="N"
                echo -e "VFIO_RAM:\tstr_input: \"$str_input\""

            else

                echo -en "VFIO_RAM:\t[Y/n]: "
                read -r str_input
                str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

                # prompt
                case $str_input in

                    "Y")

                    echo -e "VFIO_RAM:\tCreating Hugepages."
                    break;;

                    "N")

                    echo -e "VFIO_RAM:\tSkipping."
                    bool_RAM=false
                    break;;

                    *)
                    echo -e "VFIO_RAM:\tInvalid input.";;

                esac

                # counter
                echo -e "VFIO_RAM:\tint_count: \"$int_count\""
                int_count=$int_count+1    
                echo -e "VFIO_RAM:\tint_count: \"$int_count\""

            fi

        done

    fi
    #

    if [[ $bool_RAM == true ]]; then

        # reset counter
        declare -i int_count=0 

        # prompt #
        #echo -e "VFIO_RAM:\tEnter the size (integer in Gigabytes) of a single hugepage (best example: size of one same-size RAM channel/stick): "
        echo -e "VFIO_RAM:\tSystem RAM size in Kilobytes. Hint: 1 G == 1,024 M == 1,048,576 K"
        free
        #

        # after three tries, continue with default selection
        while true; do

            if [[ $int_count -ge 3 ]]; then

                echo -e "VFIO_RAM:\tExceeded max attempts. Value set to $int_hugePageSum G."

                # reset counter
                int_count=0
                break

            else

                #echo -e "VFIO_RAM:\tEnter the sum of hugepages (sum * $int_hugePageSizeG GiB) (best example: integer multiple of same-size RAM channel/stick): "
                echo -en "VFIO_RAM:\tEnter the number (integer) of hugepages ( sum == "$int_hugePageSizeG"G * number_of_hugepages ): "
                read -r str_input

                # validate input #
                str_NaN='^[0-9]+$'

                if [[ $str_input =~ "$str_NaN" || "$str_input" -lt 1 || "$str_input" -ge $int_maxMemG ]]; then echo -e "VFIO_RAM:\tInvalid input. Enter a value between 1 to $int_maxMemG G." >&2

                else
                    
                    int_hugePageSum="$str_input"
                    break
                    
                fi
                #

                # counter
                int_count=$int_count+1    

            fi

        done

        # reset line if empty
        if [[ ! -z $str_GRUBlineRAM ]]; then str_GRUBlineRAM="";

        #else str_GRUBlineRAM="default_hugepagesz=1G hugepagesz=$int_hugePageSizeG hugepages=$int_hugepageSum"; fi
        else str_GRUBlineRAM="default_hugepagesz="$int_hugePageSizeG"G hugepagesz=$int_hugePageSum hugepages=$int_hugePageSum"; fi

    fi

    #echo -e "VFIO_RAM:\tEnd."

}

# methods end #

# NOTE: add zram to setup? 

# main start #

#echo -e "Main:\t\tStart."

# dependencies #
declare -a arr_PCIBusID    
declare -a arr_PCIHWID
declare -a arr_PCIDriver
declare -a arr_PCIIndex
declare -a arr_PCIInfo
declare -a arr_VGABusID
declare -a arr_VGADriver
declare -a arr_VGAHWID
declare -a arr_VGAIndex
declare -a arr_VGAVendorBusID
declare -a arr_VGAVendorDriver
declare -a arr_VGAVendorHWID
declare -a arr_VGAVendorIndex
#

01_lspci
02_VFIO

# reset IFS #
    IFS=$SAVEIFS   # Restore original IFS
#

#echo -e "Main:\t\tEnd."

exit 0

# main end
