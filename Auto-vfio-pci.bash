#!/bin/bash

## methods start ##

function 01_FindPCI {
    
    echo "FindPCI: Start."

    # create log file #
    str_dir="/var/log/"
    str_file_1=$str_file'lspci_n.log'
    str_file_2=$str_file'lspci.log'
    str_file_3=$str_file'lspci_k.log'
    lspci -n > $str_file_1
    lspci -k > $str_file_2
    #

    # booleans #
    bool_beginParsePCI=false
    bool_beginParseVGA=false
    bool_thisVGA=false
    #

    # counter #
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
    #

    # outputs #
    declare -a arr_PCIbusID
    declare -a arr_PCIdriver
    declare -a arr_PCIhwID
    declare -a arr_VGAindex
    #

    # file 1 #
    # parse file, save PCI bus ID and PCI hardware ID to arrays
    while read str_line_1; do

        str_thisPCIbusID=${str_line_1:1:6}
        echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""

        # start read from first external PCI device
        if [[ $str_thisPCIbusID == $str_firstPCIbusID ]]; then bool_beginParsePCI=true; fi

        # save PCI hardware ID
        if [[ $bool_beginParsePCI == true ]]; then

            arr_PCIbusID+=("$str_thisPCIbusID")
            echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""
            str_thisPCIhwID=$( echo ${str_line_1:14:9} )
            echo "PCI: str_thisPCIhwID: \"$str_thisPCIhwID\""
            arr_PCIhwID+=("$str_thisPCIhwID") 
        fi

    done < $str_file_1
    # file 1 end #

    # file 2 #
    # parse file, save each driver for vfio setup, and check if indexed VGA device is not grabbed by 'vfio-pci' driver and save VGA device bus ID, hardware ID, and driver (for Xorg)
    while read str_line_2; do

        str_thisPCIbusID=${str_line_2:1:6}
        echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""
        int_len_str_line_3=${#str_line_3}-22
        str_thisPCIdriver=${str_line_3:22:$int_len_str_line_3}
        echo "PCI: str_thisPCIdriver: \"$str_thisPCIdriver\""

        # start read from first external PCI device
        if [[ $str_thisPCIbusID == $str_firstPCIbusID && $str_line_2 != *"Kernel driver in use: "* && $str_line_2 != *"Subsystem: "* && $str_line_2 != *"Kernel modules: "* ]]; then

            if [[ $str_line_2 == *"VGA compatible controller"* ]]; then bool_beginParseVGA=true
            else bool_beginParseVGA=false; fi

            bool_beginParsePCI=true

        fi

        # validate string for PCI driver
        if [[ $bool_beginParsePCI == true && $str_thisPCIdriver != "vfio-pci" && $str_line_2 == *"Kernel driver in use: "* ]]; then

            if [[ $bool_beginParseVGA == true ]]; then

                arr_VGAindex+="$int_count"
                bool_beginParseVGA=false

            else arr_PCIdriver+=("$str_thisPCIdriver"); fi

            bool_beginParsePCI=false

        fi

        echo "PCI: int_count:\"$int_count\""
        int_count=$int_count+1
        echo "PCI: int_count:\"$int_count\""

    done < $str_file_2
    # file 2 end #    

    # clear log files
    rm $str_file_1 $str_file_2   

    echo "FindPCI: End."
    
}

function 02_VFIO {

    echo "VFIO: Start."

    # dependencies #
    # bool_RAM #
    # int_count #
    # int_hugepageSizeG #
    # int_hugePageSum #
    #

    # dependency parameters #
    declare -a arr_validVGAindex
    declare -a arr_VGAdriver
    declare -a arr_VGAhwID
    #

    # local parameters #
    bool_GRUB_VGA=false
    declare -i int_count=0
    #

    # prompt #
    # ask user to enable/disable hugepages
    VFIO_RAM
    #

    # prompt #
    while true; do

        echo "VFIO: Do you wish to passthrough every VGA device?"\n"In other words, do you wish to create separate GRUB options to run Xorg with VGA devices?"\n" For example, first GRUB option will omit first VGA device, second option will omit second, and so on."\n"[Y/n]: "
        read str_input

        # after three tries, continue with default selection
        if [[ $int_count -ge 3 ]]; then

            echo "VFIO: Exceeded max attempts."
            # default selection
            str_input="Y"
            # reset counter
            int_count=0 

        else

            # string to upper
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`
            str_input=${str_input:0:1}
        fi

        # prompt
        case $str_input in

            "Y")

                echo "VFIO: Passing-through every VGA device. Skipping GRUB options."
                break;;

            "N")

                echo "VFIO: Creating GRUB options."
                bool_GRUB_VGA=true
                02_VFIO_VGA
                break
                ;;

            *)

                echo "VFIO: Invalid input.";;

        esac 

        # counter
        int_count=$int_count+1    
    done
    #

    # outputs #
    # array of PCI drivers excluding VGA drivers
    declare -a arr_PCIdriver=""

    # array of PCI hw IDs excluding VGA hardware IDs
    str_arr_PCIhwID=""

    # add PCI driver and hardware IDs to strings for VFIO
    for (( int_index=0; int_index<$[${#arr_PCIdriver[@]}]; int_index++ )); do

        element=${arr_PCIdriver[$int_index]}

        for element_2 in $arr_VGAindex; do

            if [[ $element_2 != $int_index ]]; then

                str_PCIdriver_softdep+=("#softdep $element pre: vfio vfio-pci" "$element")

                if [[ $int_index -eq "${#arr_PCIdriver[@]}-1" ]]; then str_arr_PCIhwID+=("$element");
                else str_arr_PCIhwID+=("$element,"); fi

            fi

        done

    done
    #

    ## prompt ##
    echo "VFIO: You may setup VFIO 'persistently' or through GRUB."\n"Persistent includes modifying '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*."\n"GRUB includes GRUB options of omitted, single VGA devices (example: omit a given VGA device to boot Xorg from)."\n"['ETC'/'GRUB'/'both']:"

    while true; do

        # after three tries, continue with default selection
        if [[ $int_count -ge 3 ]]; then

            echo "VFIO: Exceeded max attempts."
            # default selection
            str_input="B"
            # reset counter
            int_count=0

        else

            read str_input
            # string to upper
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`
        fi        

        # switch #
        case $str_input in

            "GRUB")
                # modify GRUB boot options only
                #02_VFIO_GRUB
                break;;

            "ETC")
                # ask user which VGA devices to passthrough OR which to avoid
                # modify modules and initramfs-tools only
                #02_VFIO_ETC
                break;;

            "BOTH")

                # execute GRUB and VFIO, save VGA devices for GRUB options
                #02_VFIO_GRUB
                #02_VFIO_ETC
                break;;

        *)
            echo "VFIO: Invalid input.";;

        esac

        # counter
        int_count=$int_count+1  

    done

    ##

    echo "VFIO: End."

}

function 02_VFIO_ETC {

    echo "VFIO_ETC: Start."

    # dependencies #
    # arr_PCIdriver #
    # str_arr_PCIhwID #
    # arr_validVGAindex #
    # $str_GRUBlineRAM #

    # directories #
    str_dir_1="/etc/modprobe.d/"
    #

    # files #
    str_file_1="/etc/default/grub"
    str_file_2="/etc/initramfs-tools/modules"
    str_file_3="/etc/modules"
    str_file_4="/etc/modprobe.d/vfio.conf"
    #

    # GRUB #
    str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$str_arr_PCIdriver vfio_pci.ids=$str_arr_PCIhwID"
    echo \n"#"\n${str_GRUBline} >> $str_file_1
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
$str_PCIdriver_softdep

vfio
vfio_iommu_type1
vfio_virqfd

# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIhwID
vfio_pci ids=$str_arr_PCIhwID
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
vfio_pci ids=$str_arr_PCIhwID"
)
    echo ${arr_file_3[@]} > $str_file_3
    #

    # modprobe.d/blacklists #
    for $element in $arr_PCIdriver[@]; do
        echo "blacklist $element" > $str_dir_1$element'.conf'
    done
    #

    # modprobe.d/vfio.conf #
    declare -a arr_file_4=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCIdriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIhwID")
    echo ${str_file_4[@]} > $str_file_4
    #

    echo "VFIO_ETC: End."

}

# NOTE: Untested
function VFIO_GRUB {

    echo "VFIO_GRUB: Start."

    # dependencies #
    # arr_PCIdriver #
    # arr_validVGAindex #
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
    #echo "FindRoot: str_rootKernel: \"$str_rootKernel\""
    #

    # root dev info #
    str_rootDiskInfo=`df -hT | grep /$`
    str_rootDev=${str_rootDiskInfo:5:4}   # example "sda1"
    #echo "FindRoot: str_rootDev: \"$str_rootDev\""
    #

    # root UUID #
    str_rootUUID=""
    declare -a arr_str_rootBlkInfo+=( `lsblk -o NAME,UUID` )
    #

    # find UUID #
    for element in ${arr_str_rootBlkInfo[@]}; do

        #echo "FindRoot: element: \"$element\""

        # root UUID match
        if [[ $bool_nextElement == true ]]; then str_rootUUID=$element; break
        else bool_nextElement=false; fi

        # root dev match
        if [[ $element == *$str_rootDev* ]]; then bool_nextElement=true; fi     

    done
    #

    # create individual VGA device GRUB options
    for element in $arr_validVGAindex; do

        # save current VGA bus ID
        str_VGAbusID=${arr_PCIbusID[$element]}

        # temporarily save VGA drivers and hardware IDs of all VGA devices except the current VGA device
        for element_2 in $arr_validVGAindex; do

            if [[ $element_2 != $element ]]; then

                declare -a arr_VGAdriver+=${arr_PCIdriver[$element]}
                declare -a arr_VGAhwID+=${arr_PCIhwID[$element]}

            fi

        done

        # GRUB command line
        str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$arr_VGAdriver,$str_arr_PCIdriver vfio_pci.ids=$arr_VGAhwID,$str_arr_PCIhwID"

        str_VGAdev=`lspci | grep $str_VGAbusID`

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

        # write to file
        echo ${arr_file_1[@]} > $str_dir_1'40_'$str_VGAbusID

    done

    echo "VFIO_GRUB: End."

}

# NOTE: Untested
function 02_VFIO_VGA {

    echo "VFIO_VGA: Start."

    # dependencies #
    # arr_PCIbusID #
    # arr_PCIdriver #
    # arr_PCIhwID #
    # arr_VGAindex #
    #

    # parameters #
    declare -i int_count=0
    #

    # outputs #
    declare -a arr_validVGAindex
    #

    echo "VFIO_VGA: Enter index of each VGA device to passthrough (separated by space). Enter '0' for all."
    
    while true; do

        # list all VGA devices #
        for element in $arr_VGAindex; do

            str_output=`lspci | grep *${arr_PCIbusID[$element]}*`
            echo "FindRoot: str_output: \"$str_output\""

            if [[ ! -z $str_ouput ]]; then echo "VFIO_VGA: $element: $str_output"; fi

        done
        #

        # prompt #
        # after three tries, continue with default selection
        if [[ $int_count -ge 3 ]]; then

            echo "VFIO: Exceeded max attempts."

            # default selection
            str_input="0"
            echo "FindRoot: str_input: \"$str_input\""

            # reset counter
            int_count=0  

        else

            echo "Enter input:"
            IFS=' ' read -r -a arr_input <<< $str_input

            # '0' for all
            if [[ $str_input == "0" ]]; then break; fi  

            for element in $arr_input; do

                for element_2 in $arr_VGAindex; do

                    # false match, subtract from old array
                    if [[ $element != $element_2 ]]; then "${arr_input[@]/$element}"

                    # if match, add to new array
                    else arr_validVGAindex+=$element; fi

                done

                # if new array is valid and old array is empty, continue
                if [[ ! -z $arr_validVGAindex && -z $arr_input ]]; then break; fi

            done

        fi
        #

        # if new array is empty, prompt error

        if [[ -z $arr_validVGAindex ]]; then echo "VFIO_VGA: Invalid input."; fi

        # counter
        echo "VFIO_RAM: int_count: \"$int_count\""
        int_count=$int_count+1    
        echo "VFIO_RAM: int_count: \"$int_count\""   

    done

    echo "VFIO_VGA: End."

}

function 02_VFIO_RAM {

    echo "VFIO_RAM: Start."

    # local parameters #
    bool_RAM=false
    declare -i int_count=0
    declare -i int_hugepageSizeG=1
    declare -i int_hugePageSum=1
    str_GRUBlineRAM=""
    #

    echo "VFIO_RAM: Do you wish to enable Hugepages?"\n"Hugepages is a feature which statically allocates system RAM to page-files, which may be used by Virtual machines."\n"For example, performance benefits include reduced/minimal memory latency."

    # after three tries, continue with default selection
    while true; do

        if [[ $int_count -ge 3 ]]; then

            echo "VFIO_RAM: Exceeded max attempts."
            # default selection
            str_input="N"
            echo "VFIO_RAM: str_input: \"$str_input\""

        else

            echo "VFIO_RAM: [Y/n]:"
            read str_input

            # prompt
            case $str_input in

                "Y")

                echo "VFIO: Creating Hugepages."
                break;;

                "N")

                echo "VFIO: Skipping."
                bool_RAM=true
                # reset counter
                int_count=0
                break
                ;;

                *)
                echo "VFIO: Invalid input.";;

            esac

            # counter
            echo "VFIO_RAM: int_count: \"$int_count\""
            int_count=$int_count+1    
            echo "VFIO_RAM: int_count: \"$int_count\""

        fi

    done

    if [[ $bool_RAM == true ]]; then

        # reset counter
        declare -i int_count=0 

        #echo "VFIO_RAM: Enter the size (integer in Gigabytes) of a single hugepage (best example: size of one same-size RAM channel/stick): "
        echo "VFIO_RAM: System RAM sizes in Kilobytes. Hint: 1 GiB == 1,024 MiB == 1,048,576 KiB"
        echo `free`

        # after three tries, continue with default selection
        while true; do

            if [[ $int_count -ge 3 ]]; then

                echo "VFIO_RAM: Exceeded max attempts."
                # reset counter
                int_count=0
                break

            else

                #echo "VFIO_RAM: Enter the sum of hugepages (sum * $int_hugepageSizeG GiB) (best example: integer multiple of same-size RAM channel/stick): "
                echo "VFIO_RAM: Enter the sum of hugepages (sum * $int_hugepageSizeG GiB):"
                read str_input

                # default selection
                int_hugePageSum=1

                # validate input
                if [[ "$str_input" -ge 0 ]] 2>/dev/null; then int_hugePageSum="$str_input";   
                else echo "VFIO: Invalid input."; fi

                # counter
                echo "VFIO_RAM: int_count: \"$int_count\""
                int_count=$int_count+1    
                echo "VFIO_RAM: int_count: \"$int_count\""

            fi

        done

        # reset line if empty
        if [[ -z $str_GRUBlineRAM ]]; then $str_GRUBlineRAM=""
        #else str_GRUBlineRAM="default_hugepagesz=1G hugepagesz=$int_hugepageSizeG hugepages=$int_hugepageSum"; fi
        else str_GRUBlineRAM="default_hugepagesz=1G hugepagesz=$int_hugepageSizeG hugepages=$int_hugepageSum"; fi

    fi

    echo "VFIO_RAM: End."

}


## methods end ##

# NOTES:
# divide large functions into smaller ones, note dependencies and order accordingly.
# VFIO should be Boot-based VFIO and Permanent VFIO, and/or Combined ( example: GRUB, and MODULES+MODPROBE.D )
# reduce repeated functions/work

# Auto VFIO-PCI TO-DO:
    # first loop: cycle list, save all PCI bus IDs to an array.
    # second loop: assume first-run for new system (no devices added to VFIO-PCI): cycle list, save all PCI drivers to an array (same size as before).
    # final loop: cycle list, save all PCI hardware IDs to an array (same size as before).
    # next function: update config files (/etc/modules, /etc/default/grub)

    # Xorg VFIO-PCI Setup TO-DO:
    # *run as a systemd service
    # first loop: cycle list, save all PCI bus IDs to an array, and save index of VGA devices to an array.
    # final loop: cycle list, stop at first VGA device without VFIO-PCI driver; find the index of the array with all PCI devices with the index of the array of VGA devices; save the VGA bus ID and driver.
    # next function: update xorg conf file

## main start ##

echo "Main: Start."

# methods #
01_FindPCI
#02_VFIO
#

echo "Main: End."

## main end ##

exit 0
