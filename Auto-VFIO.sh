#!/bin/bash

########## README ##########

# Maintainer: github/portellam

# TL;DR:
# Generates a VFIO passthrough setup (Multi-Boot or Static).

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
echo "$0: \$1 == '$1'"          # multiboot/static  [Y/B or N/S]
echo "$0: \$2 == '$2'"          # enable Evdev      [Y/E or N]
echo "$0: \$3 == '$3'"          # enable Zram       [Y/Z or N]
echo "$0: \$4 == '$4'"          # enable hugepages  [Y/H or N]
echo "$0: \$5 == '$5'"          # set size          [2M or 1G]
echo "$0: \$6 == '$6'"          # set num           [min or max]
echo -e
# example:              sudo bash $0 b e z h 1g 24
# example:              sudo bash $0 b y y y 1g 24
# example:              sudo bash $0 b n n n

########## end pre-main ##########

########## ParsePCI ##########

function ParsePCI {

    # parameters #
    #declare -a arr_PCIBusID
    #declare -a arr_PCIDriver
    #declare -a arr_PCIHWID
    #declare -a arr_VGABusID
    #declare -a arr_VGADriver
    #declare -a arr_VGAHWID
    #declare -a arr_VGAVendorBusID
    #declare -a arr_VGAVendorHWID
    bool_parseA=false
    bool_parseB=false
    bool_parseVGA=false
    #

    # set file #
    declare -a arr_lspci_k=(`lspci -k`)
    declare -a arr_lspci_m=(`lspci -m`)
    declare -a arr_lspci_n=(`lspci -n`)
    str_file2="/etc/X11/xorg.conf.d/10-Auto-Xorg.conf"
    #

    # parse list of PCI #
    #for str_line1 in $arr_lspci_m; do
    for (( int_indexA=0; int_indexA<${#arr_lspci_m[@]}; int_indexA++ )); do

        str_line1=${arr_lspci_m[$int_indexA]}    # element
        str_line3=${arr_lspci_n[$int_indexA]}    # element

        # begin parse #
        if [[ $str_line1 == *"01:00.0"* ]]; then bool_parseA=true; fi
        #

        # parse #
        if [[ $bool_parseA == true ]]; then

            # PCI info #
            str_thisPCIBusID=(${str_line1:0:7})                     # raw VGA Bus ID
            str_thisPCIType=`echo $str_line1 | cut -d '"' -f 2`     # example:  VGA
            str_thisPCIVendor=`echo $str_line1 | cut -d '"' -f 4`   # example:  NVIDIA
            str_thisPCIHWID=`echo $str_line3 | cut -d " " -f 3`     # example:  AB12:CD34
            #

            # add to list
            arr_PCIBusID+=("$str_thisPCIBusID")
            arr_PCIHWID+=("$str_thisPCIHWID") 
            #

            # match VGA device, add to list #
            if [[ $str_thisPCIType == *"VGA"* ]]; then
                arr_VGABusID+=("$str_thisPCIBusID")
                arr_VGAHWID+=("$str_thisPCIHWID")
            fi
            #

            # match VGA Vendor device, add to list #
            if [[ $str_thisPCIType != *"VGA"* && $str_prevLine1 == *"$str_thisPCIVendor"* ]]; then
                arr_VGAVendorBusID+=("$str_thisPCIBusID")
                arr_VGAVendorHWID+=("$str_thisPCIHWID")
            fi
            #

            # parse list of drivers
            #for str_line2 in $arr_lspci_k; do
            declare -i int_indexB=0
            for (( int_indexB=0; int_indexB<${#arr_lspci_k[@]}; int_indexB++ )); do
            
                str_line2=${arr_lspci_k[$int_indexB]}    # element
                #echo "str_line2 == '$str_line2'"     

                # begin parse #
                if [[ $str_line2 == *"$str_thisPCIBusID"* ]]; then bool_parseB=true; fi
                #

                # match VGA #
                if [[ $bool_parseB == true && $str_line2 == *"VGA"* ]]; then
                    bool_parseVGA=true
                fi
                #

                # match driver #
                if [[ $bool_parseB == true && $str_line2 == *"Kernel driver in use: "* && $str_line2 != *"vfio-pci"* && $str_line2 != *"Subsystem: "* && $str_line2 != *"Kernel modules: "* ]]; then
                
                    str_thisPCIDriver=`echo $str_line2 | cut -d " " -f 5`   # PCI driver
                    arr_PCIDriver+=("$str_thisPCIDriver")                   # add to list

                    # match VGA, add to list #
                    if [[ $bool_parseVGA == true ]]; then
                        arr_VGADriver+=("$str_thisPCIDriver")
                    fi

                    bool_parseB=false
                    bool_parseVGA=false         
                fi
                #

                str_prevLine2=$str_line2    # save previous line for comparison

            done
            #
        fi
        #

        str_prevLine1=$str_line1    # save previous line for comparison

    done
    #

    # Debug
    function DEBUG {

    echo -e "$0: arr_PCIBusID == ${#arr_PCIBusID[@]}i"
    for element in ${arr_PCIBusID[@]}; do
        echo -e "$0: arr_PCIBusID == "$element
    done

    echo -e "$0: arr_VGABusID == ${#arr_VGABusID[@]}i"
    for element in ${arr_VGABusID[@]}; do
        echo -e "$0: arr_VGABusID == "$element
    done

    echo -e "$0: arr_VGAVendorBusID == ${#arr_VGAVendorBusID[@]}i"
    for element in ${arr_VGAVendorBusID[@]}; do
        echo -e "$0: arr_VGAVendorBusID == "$element
    done

    echo -e "$0: arr_PCIDriver == ${#arr_PCIDriver[@]}i"
    for element in ${arr_PCIDriver[@]}; do
        echo -e "$0: arr_PCIDriver == "$element
    done

    echo -e "$0: arr_VGADriver == ${#arr_VGADriver[@]}i"
    for element in ${arr_VGADriver[@]}; do
        echo -e "$0: arr_VGADriver == "$element
    done

    echo -e "$0: arr_PCIHWID == ${#arr_PCIHWID[@]}i"
    for element in ${arr_PCIHWID[@]}; do
        echo -e "$0: arr_PCIHWID == "$element
    done

    echo -e "$0: arr_VGAHWID == ${#arr_VGAHWID[@]}i"
    for element in ${arr_VGAHWID[@]}; do
        echo -e "$0: arr_VGAHWID == "$element
    done

    echo -e "$0: arr_VGAVendorHWID == ${#arr_VGAVendorHWID[@]}i"
    for element in ${arr_VGAVendorHWID[@]}; do
        echo -e "$0: arr_VGAVendorHWID == "$element
    done
    }

    echo -e
    #

    #DEBUG

}

########## end ParsePCI ##########

########## HugePages ##########

function HugePages {

    # parameters #
    str_input=$4
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\nVirtual machines can use HugePages to a peformance benefit.\nThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

    if [[ $str_input == "N" ]]; then
    
        echo "$0: Skipping HugePages..."
        return 0;

    fi

    if [[ -z $str_input || $str_input == "Y" ]]; then echo -e $str_prompt; fi

    while [[ $str_input != "Y" && $str_input != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input="N"                   # default selection
        
        else

            echo -en "$0: Setup HugePages?\t[Y/n]: "
            read -r str_input
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input in

            "Y"|"H")
                echo "$0: Continuing..."
                break;;

            "N")
                echo "$0: Skipping..."
                return 0;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    # Hugepage size: validate input #
    str_HugePageSize=$5
    str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

    declare -i int_count=0      # reset counter

    while true; do
                 
        # attempt #
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_HugePageSize="1G"           # default selection
        
        else

            echo -en "$0: Enter Hugepage size and byte-size. [ 2M / 1G ]:\t"
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
                echo "$0: Invalid input.";;

        esac
        #

        ((int_count++))                     # inc counter

    done
    #

    # Hugepage sum: validate input #
    int_HugePageNum=$6
    declare -i int_count=0      # reset counter

    while true; do

        # attempt #
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
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

            echo -en "$0: Enter number of HugePages ( num * $str_HugePageSize ). [ $int_HugePageMin to $int_HugePageMax pages ] : "
            read -r int_HugePageNum
            #

        fi
        #

    # check input #
    if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then

        echo "$0: Invalid input."
        ((int_count++));     # inc counter

    else
    
        echo -e "$0: Continuing..."
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"
        break
        
    fi
    #

    done
    #

}

########## end HugePages ##########

########## Prompts ##########

function Prompts {

    # parameters #
    str_input=$1
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically.\n$0: Multi-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n$0: Static Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n$0: Multi-boot is the more flexible choice.\n"

    if [[ -z $str_input ]]; then echo -e $str_prompt; fi

    while [[ $str_input != "B" && $str_input != "S" && $str_input != "Y" && $str_input != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input="B"                   # default selection
        
        else

            echo -en "$0: Setup VFIO?\t[ Multi-(B)oot / (S)tatic ]: "
            read -r str_input
            str_input=`echo $str_input | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input in

            "Y"|"B")
                echo "$0: Continuing with Multi-Boot setup..."
                HugePages $4 $5 $6
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                #StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                break;;

            "N"|"S")
                echo "$0: Continuing with Static setup..."
                HugePages $4 $5 $6
                StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

}

########## end Prompts ##########

########## MultiBootSetup ##########

# NOTE: make sure proper backups of etc files are made! I had to download raw from github to restore them here!

function MultiBootSetup {

    # dependencies # 
    declare -a arr_PCIBusID
    declare -a arr_PCIDriver
    declare -a arr_PCIHWID
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    declare -a arr_VGAHWID
    declare -a arr_VGAVendorBusID
    declare -a arr_VGAVendorHWID
    ParsePCI $arr_PCIBusID $arr_PCIDriver $arr_PCIHWID $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAVendorBusID $arr_VGAVendorHWID 
    #

    # Debug
    function DEBUG {

        echo -e "arr_PCIBusID == ${#arr_PCIBusID[@]}i"
        for element in ${arr_PCIBusID[@]}; do
            echo -e "arr_PCIBusID == "$element
        done

        echo -e "arr_VGABusID == ${#arr_VGABusID[@]}i"
        for element in ${arr_VGABusID[@]}; do
            echo -e "arr_VGABusID == "$element
        done

        echo -e "arr_VGAVendorBusID == ${#arr_VGAVendorBusID[@]}i"
        for element in ${arr_VGAVendorBusID[@]}; do
           echo -e "arr_VGAVendorBusID == "$element
        done

        echo -e "arr_PCIDriver == ${#arr_PCIDriver[@]}i"
        for element in ${arr_PCIDriver[@]}; do
           echo -e "arr_PCIDriver == "$element
        done

        echo -e "arr_VGADriver == ${#arr_VGADriver[@]}i"
        for element in ${arr_VGADriver[@]}; do
           echo -e "arr_VGADriver == "$element
        done

        echo -e "arr_PCIHWID == ${#arr_PCIHWID[@]}i"
        for element in ${arr_PCIHWID[@]}; do
           echo -e "arr_PCIHWID == "$element
        done

        echo -e "arr_VGAHWID == ${#arr_VGAHWID[@]}i"
        for element in ${arr_VGAHWID[@]}; do
            echo -e "arr_VGAHWID == "$element
        done

        echo -e "arr_VGAVendorHWID == ${#arr_VGAVendorHWID[@]}i"
        for element in ${arr_VGAVendorHWID[@]}; do
            echo -e "arr_VGAVendorHWID == "$element
        done
}
    #
    DEBUG
    #

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
exec tail -n +3 \$0
# This file provides an easy way to add custom menu entries. Simply type the
# menu entries you want to add after this comment. Be careful not to change
# the 'exec tail' line above.
" > $str_file1

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

        echo -e "GRUB:\int_VGAIndex: \"$int_VGAIndex\""
        echo -e "GRUB:\str_thisVGABusID: \"$str_thisVGABusID\""
        echo -e "GRUB:\str_thisVGADriver: \"$str_thisVGADriver\""
        echo -e "GRUB:\str_thisVGAHWID: \"$str_thisVGAHWID\""

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
            str_GRUBline="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUBlineRAM modprobe.blacklist=$arr_VGADriver,$str_arr_PCIDriver vfio_pci.ids=$arr_VGAHWID,$arr_PCIHWID"
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

                #echo -e "\n${arr_file_customGRUB[@]}" > $str_file1      # write to file
            done   
            #
        done
        #
    done
    #

}

########## end MultiBootSetup ##########

########## main ##########

Prompts $1 $2 $3 $4 $5 $6

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
########## end main ##########


