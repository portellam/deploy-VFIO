#!/bin/bash

## set IFS ##
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
##

########## find PCI devices ##########

## parameters ##
str_CPUbusID="00:00.0"
str_thisPCIBusID=""
str_prevPCIBusID=""
str_VGAVendor=""
##

## lists ##
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
##

## create log file ##
str_dir="/var/log/"
str_file_PCIInfo=$str_dir'lspci.log'
str_file_PCIDriver=$str_dir'lspci-k.log'
str_file_PCIHWID=$str_dir'lspci-n.log'
lspci | grep ":00." > $str_file_PCIInfo
lspci -k > $str_file_PCIDriver
lspci -n | grep ":00." > $str_file_PCIHWID
##

## find external PCI device Index values, Bus ID, and drivers ##
bool_parsePCI=false
bool_parseVGA=false
bool_parseVGAVendor=false
declare -i int_index=0
##

#### parse list of PCI devices ####
function VFIO_parse {

    while read -r str_line; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        if [[ $bool_parsePCI == true ]]; then

            if [[ $str_line != *"Subsystem: "* && $str_line != *"Kernel driver in use: "* && $str_line != *"Kernel modules: "* ]]; then     # line includes PCI bus ID

                ((int_index++))                     # increment only if Bus ID is found
                arr_PCIInfo+=($str_line)            # add line to list
                str_thisPCIBusID=(${str_line:0:7})
                arr_PCIBusID+=($str_thisPCIBusID)   # add Bus ID index to list

                ## match VGA device ##
                if [[ $str_line == *"VGA"* ]]; then
            
                    arr_VGABusID+=($str_thisPCIBusID);
                    str_prevPCIBusID=($str_thisPCIBusID)
                    bool_parseVGA=true

                fi
                ##

                ## match VGA vendor device (Audio, USB3, etc.) ##
                if [[ ${str_thisPCIBusID:0:6} == ${str_prevPCIBusID:0:6} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then

                    arr_VGAVendorBusID+=($str_thisPCIBusID);
                    bool_parseVGAVendor=true

                fi
                ##

            fi

        fi

        ## add to list only if driver is found ##
        if [[ $str_line == *"Kernel driver in use: "* ]]; then      # line includes PCI driver

            declare -i int_offset=${#str_line}-22
            str_thisPCIDriver=${str_line:23:$int_offset}
            arr_PCIDriver+=($str_thisPCIDriver)
            arr_PCIIndex+=("$int_index")        

            ## add to lists only if VGA device ##
            if [[ $bool_parseVGA == true ]]; then

                arr_VGAIndex+=("$int_index")
                arr_VGADriver+=($str_thisPCIDriver);                # save for blacklists and Xorg

            fi
            ##

            ## add to list only if VGA vendor device ##
            if [[ $bool_parseVGAVendor == true ]]; then

                arr_VGAVendorIndex+=("$int_index");
                arr_VGAVendorDriver+=("$str_thisPCIDriver")  

            fi
            ##

            ## reset booleans ##
            bool_parseVGA=false
            bool_parseVGAVendor=false
            ##

        fi
        ##

    done < $str_file_PCIDriver
    ####

    ## find external PCI Hardware IDs ##
    bool_parseVGAVendor=false
    declare -i int_index=0

    #### parse list of PCI devices ####
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

    done < $str_file_PCIHWID
}
####

##
function VFIO_parse_debug {

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

VFIO_parse           # parse lists
VFIO_parse_debug     # run debug

########## end find PCI devices ##########

########## VFIO functions ##########

# TODO: test
## ETC ##
function VFIO_ETC {

    VFIO_parse           # parse lists
    VFIO_parse_debug     # run debug

    #str_dir_modprobed="/etc/modprobe.d/"   # directories

    ## files ##
    #str_file_GRUB="/etc/default/grub"
    #str_file_initramfs="/etc/initramfs-tools/modules"
    #str_file_modules="/etc/modules"
    #str_file_vfio="/etc/modprobe.d/vfio.conf"
    str_file_GRUB="0_grub.log"
    str_file_initramfs="0_initramfs.log"
    str_file_modules="0_modules.log"
    str_file_vfio="0_vfio.log"
    touch $str_file_GRUB $str_file_initramfs $str_file_modules $str_file_vfio
    ##

    ## GRUB ##
    str_GRUBline="GRUB_CMDLINE_LINUX=acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$str_arr_PCIDriver vfio_pci.ids=$str_arr_PCIHWID"
    echo -e "\n#\n${str_GRUBline}" >> $str_file_GRUB
    ##

    ## initramfs-tools ##
    declare -a arr_file_initramfs=(
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

    echo -e "\n${arr_file_initramfs[@]}" > $str_file_initramfs
    #

    # modules #
    declare -a arr_file_modules=(
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
    echo -e "\n${arr_file_modules[@]}" > $str_file_modules
    #

    # modprobe.d/blacklists #
    for element in $arr_PCIDriver[@]; do
        echo "blacklist $element" > $str_dir_modprobe$element'.conf'
    done
    #

    # modprobe.d/vfio.conf #
    declare -a arr_file_vfio=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCIDriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_arr_PCIHWID")
    echo -e "\n${arr_file_vfio[@]}" > $str_file_vfio
    #

}

## GRUB ##                      # NOTE: test!
# NOTE: test!
function VFIO_GRUB {

    VFIO_parse           # parse lists
    VFIO_parse_debug     # run debug

    #### parameters ####
    str_GRUBtitle="Debian "`uname -o`", with"`uname -r` # grub menu entry
    str_rootKernel=`uname -r`                           # active kernel
    
    ## root dev info ##
    str_rootDiskInfo=`df -hT | grep /$`
    str_rootDev=${str_rootDiskInfo:5:4}   # example "sda1"
    ##

    ## root UUID ##
    str_rootUUID=""
    declare -a arr_str_rootBlkInfo+=( `lsblk -o NAME,UUID` )
    ##

    ## custom GRUB ##
    str_file_customGRUB="/etc/grub.d/proxifiedScripts/custom"
    if [[ ! -z $str_file_customGRUB"_old" ]]; then

        cp $str_file_customGRUB $str_file_customGRUB"_old"
        echo -e "#!/bin/sh
exec tail -n +3 /home/user/test-findpci.bash
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above." > $str_file_customGRUB

    fi
    ##

    ####

    ## find UUID ##
    for element in ${arr_str_rootBlkInfo[@]}; do

        ## root UUID match ##
        if [[ $bool_nextElement == true ]]; then str_rootUUID=$element; break
        else bool_nextElement=false; fi
        ##

        if [[ $element == *$str_rootDev* ]]; then bool_nextElement=true; fi     # root dev match

    done
    ##

    ## create individual VGA device GRUB options ##
    for element in $arr_VGAIndex; do
        
        str_thisVGABusID="${arr_VGABusID[$element]}"
        str_thisVGADriver="${arr_VGADriver[$element]}"
        str_thisVGAHWID="${arr_VGAHWID[$element]}"

        echo -e "VFIO_GRUB:\telement: \"$element\""
        echo -e "VFIO_GRUB:\str_thisVGABusID: \"$str_thisVGABusID\""
        echo -e "VFIO_GRUB:\str_thisVGADriver: \"$str_thisVGADriver\""
        echo -e "VFIO_GRUB:\str_thisVGAHWID: \"$str_thisVGAHWID\""

        ## add to list, separate by comma ##
        for (( int_index=0; int_index<${#arr_PCIIndex[@]}; int_index++ )); do

            ## save current index ##
            element_2=${arr_PCIIndex[int_index]}
            str_thisPCIDriver=${arr_PCIDriver[$element_2]}

            if [[ $element_2 != $element ]]; then
            
                str_listPCIBusID+="${arr_PCIBusID[$element_2]},"
                str_listPCIHWID+="${arr_PCIHWID[$element_2]},"
                
            fi

            if [[ $str_thisPCIDriver != $str_thisVGADriver ]]; then
            
                str_listPCIDriver+="${arr_PCIBusID[$element_2]},"
                
            fi

            ## last index ##
            if [[ $element_2 != $element && $int_index == ${#arr_PCIIndex[@]}-1 ]]; then
            
                str_listPCIBusID+="${arr_PCIBusID[$element_2]}"
                str_listPCIHWID+="${arr_PCIHWID[$element_2]}"
            
            fi

            if [[ $str_thisPCIDriver != $str_thisVGADriver && $int_index == ${#arr_PCIIndex[@]}-1 ]]; then
            
                str_listPCIDriver+="${arr_PCIBusID[$element_2]}"
                
            fi
            ##

            ## GRUB command line ##
            str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$arr_VGADriver,$str_arr_PCIDriver vfio_pci.ids=$arr_VGAHWID,$str_arr_PCIHWID"
            ##

            ## GRUB custom menu ##
            declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBtitle (Xorg: $str_thisVGABusID: $str_thisVGADriver)' {
    insmod gzio
    set root='/dev/$str_rootDev'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUBline
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
    echo    'Xorg: $str_thisVGABusID: $str_thisVGADriver'"
            )   
            ##   

            echo -e "\n${arr_file_customGRUB[@]}" > $str_file_customGRUB      # write to file

        done
        ##

    done
    ##

}
##

## Hugepages ##                 # NOTE: works!
function VFIO_RAM {

    VFIO_parse           # parse lists
    VFIO_parse_debug     # run debug

    ## parameters ##
    str_GRUBlineRAM=""
    bool_RAM=false
    declare -i int_count=0
    str_hugePageSize="1G"           # NOTE: ask user if they want to use 1G or 2M hugepage size, adjust warnings accordingly. recommend 1G hugepages as default.
    declare -i int_hugePageSum=1
    ##

    echo -e "VFIO_RAM:\tDo you wish to enable Hugepages?\nHugepages is a feature which statically allocates system RAM to page-files, which may be used by Virtual machines.\nFor example, performance benefits include reduced/minimal memory latency."

    ## after three tries, continue with default selection ##
    while true; do

        if [[ $int_count -ge 3 ]]; then

            echo -e "VFIO_RAM:\tExceeded max attempts."
            str_input="N"       # default selection 
            echo -e "VFIO_RAM:\tstr_input: \"$str_input\""  # DEBUG

        else

            echo -en "VFIO_RAM:\t[Y/n]: "
            read -r str_input
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

            ## prompt ##
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
            ##

            int_count=$int_count+1      # reset counter  

        fi

    done
    ##

    int_hugePageSum=1   # default selection

    ## find total RAM ##
    str_sumMemK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`
    declare -i int_sumMemK=$str_sumMemK
    declare -i int_maxMemG=($int_sumMemK/1024/1024)
    int_maxMemG=($int_maxMemG-4)
    ###

    ## skip if max RAM is too little ##
    if [[ $int_maxMemG -le 1 ]]; then
        
        echo -e "VFIO_RAM:\tSystem RAM is too limited to create hugepages. Skipping."
        bool_RAM=false    
            
    fi
    ##

    ## warn if max RAM may be too little ## 
    if [[ $int_maxMemG -le 4 && $int_maxMemG -gt 1 ]]; then

        echo -e "VFIO_RAM:\tSystem RAM may be too limited to create hugepages. Continue?"

        while true; do

            if [[ $int_count -ge 3 ]]; then

                echo -e "VFIO_RAM:\tExceeded max attempts."                
                str_input="N"   # default selection
                echo -e "VFIO_RAM:\tstr_input: \"$str_input\""  # DEBUG

            else

                echo -en "VFIO_RAM:\t[Y/n]: "
                read -r str_input
                str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

                ## prompt ##
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
                ##

                int_count=$int_count+1      # reset counter

            fi

        done

    fi
    ##

    if [[ $bool_RAM == true ]]; then

        declare -i int_count=0      # reset counter

        ## prompt ##
        #echo -e "VFIO_RAM:\tEnter the size (integer in Gigabytes) of a single hugepage (best example: size of one same-size RAM channel/stick): "
        echo -e "VFIO_RAM:\tSystem RAM size in Kilobytes. Hint: 1 G == 1,024 M == 1,048,576 K"
        free
        ##

        ## after three tries, continue with default selection ##
        while true; do

            if [[ $int_count -ge 3 ]]; then

                echo -e "VFIO_RAM:\tExceeded max attempts. Value set to $int_hugePageSum G."
                int_count=0     # reset counter
                break

            else

                #echo -e "VFIO_RAM:\tEnter the number of the hugepage size ( size_of_hugepage == sum / number_of_hugepages ) (best example: integer multiple of same-size RAM channel/stick): "
                echo -en "VFIO_RAM:\tEnter the number (integer) of hugepages ( sum == $str_hugePageSize * number_of_hugepages ): "
                read -r str_input

                ## validate input ##
                str_NaN='^[0-9]+$'

                if [[ $str_input =~ "$str_NaN" || "$str_input" -lt 1 || "$str_input" -ge $int_maxMemG ]]; then echo -e "VFIO_RAM:\tInvalid input. Enter a value between 1 to $int_maxMemG G." >&2

                else
                    
                    int_hugePageSum="$str_input"
                    break
                    
                fi
                ##

                int_count=$int_count+1      # reset counter

            fi

        done

        ## reset line if empty ##
        if [[ ! -z $str_GRUBlineRAM ]]; then str_GRUBlineRAM="";

        #else str_GRUBlineRAM="default_hugepagesz=$str_hugePageSize hugepagesz=$str_hugePageSize hugepages=$int_hugepageSum"; fi
        else str_GRUBlineRAM="default_hugepagesz=$str_hugePageSize hugepagesz=$str_hugePageSize hugepages=$int_hugePageSum"; fi
        ##

    fi

}
##

##########

# TODO: test
########## setup VFIO ##########

VFIO_RAM                        # prompt: ask user to enable/disable hugepages

## parameters ##
bool_GRUB_VGA=false
declare -i int_count=0          # reset counter
declare -a arr_PCIDriver=""     # array of PCI drivers excluding VGA drivers
str_arr_PCIHWID=""              # array of PCI hw IDs excluding VGA hardware IDs
##

## add PCI driver and hardware IDs to strings for VFIO ##
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
##

## prompt ##
echo -e "VFIO:\t\tYou may setup VFIO 'persistently' or through GRUB.\nPersistent includes modifying '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*'.\nGRUB includes multiple GRUB options of omitted, single VGA devices (example: omit a given VGA device to boot Xorg from)."

while true; do

    ## after three tries, continue with default selection
    if [[ $int_count -ge 3 ]]; then

        echo -e "VFIO:\t\tExceeded max attempts."
        str_input="B"   # default selection
        int_count=0     # reset counter

    else

        echo -en "VFIO:\t\t['ETC'/'GRUB'/'both']: "
        read -r str_input
        str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`    # string to upper

    fi        
    ##

    ## switch ##
    case $str_input in

        "GRUB")         # modify GRUB boot options only
            
            VFIO_GRUB
            break;;

        "ETC")          # modify modules and initramfs-tools only
            
            
            VFIO_ETC    # ask user which VGA devices to passthrough OR which to avoid
            break;;

        "BOTH")         # execute GRUB and VFIO, save VGA devices for GRUB options

            VFIO_GRUB
            VFIO_ETC
            break;;

        *)
            echo -e "VFIO:\t\tInvalid input.";;

    esac
    ##

    int_count=$int_count+1  # counter

done
##

########## end setup VFIO ##########

## reset IFS ##
IFS=$SAVEIFS   # Restore original IFS
##

## remove log files ##
rm $str_file_PCIInfo $str_file_PCIDriver $str_file_PCIHWID
##

exit 0
