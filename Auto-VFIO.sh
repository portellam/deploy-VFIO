#!/bin/bash

########## README ##########

# TODO:
#   StaticSetup
#   prompt user to install/execute Auto-Xorg.
#   setup input parameter passthrough
#   Virtual audio, Scream?
#

# DONE:
#   ParsePCI
#   Prompts
#   MultiBootSetup
#   Hugepages
#   ZRAM
#
#

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

########## end pre-main ##########

########## ParsePCI ##########

function ParsePCI {

    # parameters #
    #declare -a arr_PCIBusID
    #declare -a arr_PCIDriver
    #declare -a arr_PCIHWID
    #declare -a arr_VGABusID
    ##declare -a arr_VGADriver          ## unused
    ##declare -a arr_VGAHWID            ## unused
    ##declare -a arr_VGAVendorBusID     ## unused
    ##declare -a arr_VGAVendorHWID      ## unused
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
            #if [[ $str_thisPCIType != *"VGA"* && $str_prevLine1 == *"$str_thisPCIVendor"* ]]; then
                #arr_VGAVendorBusID+=("$str_thisPCIBusID")
                #arr_VGAVendorHWID+=("$str_thisPCIHWID")
            #fi
            #

            # parse list of drivers
            #for str_line2 in $arr_lspci_k; do
            declare -i int_indexB=0
            for (( int_indexB=0; int_indexB<${#arr_lspci_k[@]}; int_indexB++ )); do
            
                str_line2=${arr_lspci_k[$int_indexB]}    # element   

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

    #echo -e "$0: arr_VGAVendorBusID == ${#arr_VGAVendorBusID[@]}i"
    #for element in ${arr_VGAVendorBusID[@]}; do
        #echo -e "$0: arr_VGAVendorBusID == "$element
    #done

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

    #echo -e "$0: arr_VGAVendorHWID == ${#arr_VGAVendorHWID[@]}i"
    #for element in ${arr_VGAVendorHWID[@]}; do
        #echo -e "$0: arr_VGAVendorHWID == "$element
    #done
    }

    echo -e
    #

    #DEBUG

}

########## end ParsePCI ##########

########## HugePages ##########

function HugePages {

    # parameters #
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

    echo -e $str_prompt
    str_input1=""

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Setup HugePages?\t[Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

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
    str_HugePageSize=$str6
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
    echo -e ""
    int_HugePageNum=$str7
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

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically.\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice.\n"

    if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

    while [[ $str_input1 != "M" && $str_input1 != "S" && $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="M"                   # default selection
        
        else

            echo -en "$0: Setup VFIO?\t[ (M)ulti-Boot / (S)tatic ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y"|"M")
                echo "$0: Continuing with Multi-Boot setup..."
                HugePages $str_GRUB_CMDLINE_Hugepages
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                #StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                break;;

            "N"|"S")
                echo "$0: Continuing with Static setup..."
                HugePages $str_GRUB_CMDLINE_Hugepages
                StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    EvDev
    ZRAM

}

########## end Prompts ##########

########## MultiBootSetup ##########

# NOTE: make sure proper backups of etc files are made! I had to download raw from github to restore them here!
# NOTE: function needs work before testing

function MultiBootSetup {

    echo -e ""
    str_input1=""

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Do you wish to Review each VGA device to Passthrough or not passthrough, before creating a given GRUB menu entry?"

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Review each VGA device, or not?\t[Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y")
                echo "$0: Continuing Multi-Boot setup manually..."
                break;;

            "N")
                echo "$0: Continuing Multi-Boot setup automated..."
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    # dependencies # 
    declare -a arr_PCIBusID
    declare -a arr_PCIDriver
    declare -a arr_PCIHWID
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    ParsePCI $arr_PCIBusID $arr_PCIDriver $arr_PCIHWID $arr_VGABusID $arr_VGADriver
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

        echo -e "arr_PCIDriver == ${#arr_PCIDriver[@]}i"
        for element in ${arr_PCIDriver[@]}; do
           echo -e "arr_PCIDriver == "$element
        done


        echo -e "arr_PCIHWID == ${#arr_PCIHWID[@]}i"
        for element in ${arr_PCIHWID[@]}; do
           echo -e "arr_PCIHWID == "$element
        done

    }
    #
    #DEBUG
    #

    ## parameters ##
    str_Distribution=`lsb_release -i`   # Linux distro name
    declare -i int_Distribution=${#str_Distribution}-16
    str_Distribution=${str_Distribution:16:int_Distribution}
    declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2`)                                # list of Kernels
    #

    # root Dev #
    str_rootDiskInfo=`df -hT | grep /$`
    #str_rootDev=${str_rootDiskInfo:5:4}     # example "sda1"
    str_rootDev=${str_rootDiskInfo:0:9}     # example "/dev/sda1"
    str_rootUUID=`sudo lsblk -n $str_rootDev -o UUID`
    #

    # custom GRUB #
    #str_file1="/etc/grub.d/proxifiedScripts/custom"
    str_file1="/etc/grub.d/40_custom"
    echo -e "#!/bin/sh
exec tail -n +3 \$0
# This file provides an easy way to add custom menu entries. Simply type the
# menu entries you want to add after this comment. Be careful not to change
# the 'exec tail' line above.
" > $str_file1
    #
    ##

    ## parse GRUB menu entries ##
    declare -i int_lastIndexPCI=${#arr_PCIBusID[@]}-1
    declare -i int_lastIndexVGA=${#arr_VGABusID[@]}-1
    
    # parse list of VGA devices #
    for (( int_indexVGA=0; int_indexVGA<${#arr_VGABusID[@]}; int_indexVGA++ )); do

        bool_parsePCIifExternal=false
        bool_parseEnd=false
        str_thisVGABusID=${arr_VGABusID[$int_indexVGA]}             # save for match
        str_thisVGADriver=${arr_VGADriver[$int_indexVGA]}           # save for GRUB
        str_thisVGADevice=`lspci -m | grep $str_thisVGABusID | cut -d '"' -f 6`
        str_listPCIDriver=""
        str_listPCIHWID=""

        #
        if [[ $str_input1 == "Y" ]]; then

            # prompt #
            declare -i int_count=0      # reset counter
            echo -en "$0: " && lspci -m | grep $str_thisVGABusID

            while [[ $str_input2 != "Y" && $str_input2 != "N" ]]; do

                if [[ $int_count -ge 3 ]]; then

                    echo "$0: Exceeded max attempts."
                    str_input2="N"                   # default selection
        
                else

                    echo -en "$0: Do you wish to passthrough this VGA device (or not)?\t[Y/n]: "
                    read -r str_input2
                    str_input2=`echo $str_input2 | tr '[:lower:]' '[:upper:]'`

                fi

                case $str_input2 in

                    "Y")
                        echo "$0: Passing-through VGA device..."
                        break;;

                    "N")
                        echo "$0: Omitting VGA device..."
                        break;;

                    *)
                        echo "$0: Invalid input.";;

                esac
                ((int_count++))

            done
            #
        fi
        #

        # default choice: if NOT passing-through device, run loop #
        if [[ $str_input2 != "Y" ]]; then

            # parse list of PCI devices #
            for (( int_indexPCI=0; int_indexPCI<${#arr_PCIBusID[@]}; int_indexPCI++ )); do

                str_thisPCIBusID=${arr_PCIBusID[$int_indexPCI]}         # save for match
                str_thisPCIDriver=${arr_PCIDriver[$int_indexPCI]}       # save for GRUB
                str_thisPCIHWID=${arr_PCIHWID[$int_indexPCI]}           # save for GRUB    

                # if PCI is an expansion device, parse it #
                if [[ $str_thisPCIBusID == "01:00.0" ]]; then bool_parsePCIifExternal=true; fi
                #

                # match VGA device exactly #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} && $str_thisVGABusID == $str_thisPCIBusID ]]; then
                    
                    # clear variables #
                    str_thisPCIDriver=""
                    str_thisPCIHWID=""
                    #

                fi

                # match VGA device's child interface #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} && $str_thisVGABusID != $str_thisPCIBusID ]]; then
                
                    str_thisVGAChildDriver=$str_thisPCIDriver

                    # clear variables #
                    str_thisPCIDriver=""
                    str_thisPCIHWID=""
                    #

                fi

                # match driver and no partial match Bus ID, clear driver #
                if [[ $str_thisVGADriver == $str_thisPCIDriver && $str_thisVGABusID != $str_thisPCIBusID ]]; then str_thisPCIDriver=""; fi
                #

                # partial match Bus ID, clear PCI child driver #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} ]]; then str_thisPCIDriver=""; fi
                #

                # if VGA child driver match found, clear driver #
                if [[ $str_thisPCIDriver == $str_thisVGAChildDriver ]]; then str_thisPCIDriver=""; fi
                #

                # if PCI driver is already present in list, clear driver #
                if [[ $str_listPCIDriver == *"$str_thisPCIDriver"* ]]; then str_thisPCIDriver=""; fi
                #

                # if no PCI driver match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIDriver ]]; then str_listPCIDriver+="$str_thisPCIDriver,"; fi
                #
                
                # if no PCI HW ID match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIHWID ]]; then str_listPCIHWID+="$str_thisPCIHWID,"; fi
                #

            done  
            # end parse list of PCI devices #

            # remove last separator #
            if [[ ${str_listPCIDriver: -1} == "," ]]; then str_listPCIDriver=${str_listPCIDriver::-1}; fi
            if [[ ${str_listPCIHWID: -1} == "," ]]; then str_listPCIHWID=${str_listPCIHWID::-1}; fi
            #
  
            echo -e ""

            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID"

            ### setup Boot menu entry ###           # TODO: fix automated menu entry setup!

            # parse Kernels #
            for str_rootKernel in ${arr_rootKernel[@]}; do

                # set Kernel #
                str_rootKernel=${str_rootKernel:1:100}          # arbitrary length
                #echo "str_rootKernel == '$str_rootKernel'"
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` $str_rootKernel"
                if [[ ! -z $str_thisVGADevice ]]; then
                    str_GRUBMenuTitle+=" (Xorg: $str_thisVGADevice)'"
                fi
                #

                # MANUAL setup Boot menu entry ###    # NOTE: temporary
                echo -e "$0: Automated GRUB menu entry feature not available. Execute GRUB Customizer, copy a valid entry, and place the following output into a new entry.\n\n\tTitle: '$str_GRUBMenuTitle'\n\tEntry: '$str_GRUB_CMDLINE'\n"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    insmod gzio
    set root='/dev/disk/by-uuid/$str_rootUUID'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
}"
                )

                # write to file
                echo -e "\n" >> $str_file1    

                #for str_line in ${arr_file_customGRUB[@]}; do
                    #echo -e $str_line >> $str_file1                     # TODO: fix GRUB menu entries!
                    #echo -e $str_line                # for now, output GRUB COMMAND LINE to terminal for user to copy to GRUB customizer
                #done
                #
            done
            #

            ## setup final GRUB entry with all PCI devices passed-through (for headless setup) ##
            str_listPCIDriver=""
            str_listPCIHWID=""

            # parse list of PCI devices #
            for (( int_indexPCI=0; int_indexPCI<${#arr_PCIBusID[@]}; int_indexPCI++ )); do

                str_thisPCIBusID=${arr_PCIBusID[$int_indexPCI]}         # save for match
                str_thisPCIDriver=${arr_PCIDriver[$int_indexPCI]}       # save for GRUB
                str_thisPCIHWID=${arr_PCIHWID[$int_indexPCI]}           # save for GRUB    

                # if PCI is an expansion device, parse it #
                if [[ $str_thisPCIBusID == "01:00.0" ]]; then bool_parsePCIifExternal=true; fi
                #

                # if PCI driver is already present in list, clear driver #
                if [[ $str_listPCIDriver == *"$str_thisPCIDriver"* ]]; then str_thisPCIDriver=""; fi
                #

                # if no PCI driver match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIDriver ]]; then str_listPCIDriver+="$str_thisPCIDriver,"; fi
                #
                
                # if no PCI HW ID match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIHWID ]]; then str_listPCIHWID+="$str_thisPCIHWID,"; fi
                #

            done  
            # end parse list of PCI devices #

            # remove last separator #
            if [[ ${str_listPCIDriver: -1} == "," ]]; then str_listPCIDriver=${str_listPCIDriver::-1}; fi
            if [[ ${str_listPCIHWID: -1} == "," ]]; then str_listPCIHWID=${str_listPCIHWID::-1}; fi
            #

            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID"
            #

            # parse Kernels #
            for str_rootKernel in ${arr_rootKernel[@]}; do

                # set Kernel #
                str_rootKernel=${str_rootKernel:1:100}          # arbitrary length
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` $str_rootKernel (Xorg: N/A)"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    insmod gzio
    set root='/dev/disk/by-uuid/$str_rootUUID'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
}"
            )

                # write to file
                echo -e "\n" >> $str_file1    

                #for str_line in ${arr_file_customGRUB[@]}; do
                    #echo -e $str_line >> $str_file1               # TODO: fix GRUB menu entries!
                    #echo -e $str_line
                #done
                #
            done
            ##

            if [[ $str_input2 == "N" ]]; then str_input2=""; fi    # reset input

        fi
        #
    done
    # end parse list of VGA devices #
    ## end parse GRUB menu entries ##

    #sudo update-grub    # update GRUB for good measure     # TODO: reenable when automated setup is fixed!

}

########## end MultiBootSetup ##########

########## EvDev ##########

function EvDev {

    # parameters #
    str_file1="/etc/libvirt/qemu.conf"
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Setup EvDev?\nEvDev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\n\tEvDev is recommended for setups without an external KVM switch and multiple USB controllers.\n\tNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

    echo -e $str_prompt

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

        "Y"|"E")
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
    declare -a arr_InputDeviceID=`ls /dev/input/by-id`
    #

    # file changes #
    declare -a arr_file_QEMU=("
#
# NOTE: Generated by 'Auto-vfio-pci.sh'
#
user = \"$str_UID1000\"
group = \"user\"
#
hugetlbfs_mount = \"/dev/hugepages\"
#
nvram = [
   \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\"
]
#
cgroup_device_acl = [
")

    for str_InputDeviceID in $arr_InputDeviceID; do arr_file_QEMU+=("    \"/dev/input/by-id/$str_InputDeviceID\","); done

    arr_file_QEMU+=("    \"/dev/null\", \"/dev/full\", \"/dev/zero\",
    \"/dev/random\", \"/dev/urandom\",
    \"/dev/ptmx\", \"/dev/kvm\",
    \"/dev/rtc\", \"/dev/hpet\"
]
#")
    #

    # backup config file #
    if [[ -z $str_file1"_old" ]]; then cp $str_file1 $str_file1"_old"; fi
    if [[ ! -z $str_file1"_old" ]]; then cp $str_file1"_old" $str_file1; fi
    #

    # write to file #
    for str_line in ${arr_file_QEMU[@]}; do echo -e $str_line >> $str_file1; done
    #

    # restart service #
    systemctl enable libvirtd
    systemctl restart libvirtd
    #

}

########## end EvDev ##########

########## ZRAM ##########

function ZRAM {

    # parameters #
    str_file1="/etc/default/zramswap"
    str_file2="/etc/default/zram-swap"
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="Setup ZRAM? ZRAM allocates RAM as a compressed swapfile. The default compression method \"lz4\", at a ratio of 2:1, offers the highest performance."

    echo -e $str_prompt
    str_input1=""

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

        "Y"|"Z")
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

        apt install -y git zram-tools
        systemctl stop zramswap
        systemctl disable zramswap

    fi
    #

    # check for local repo #
    #if [[ ! -z "/root/git/$str_GitHub_Repo" ]]; then

        #cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`    
        #git pull https://www.github.com/$str_GitHub_Repo
    
    #fi

    if [[ -z "/root/git/$str_GitHub_Repo" ]]; then
    
        mkdir /root/git
        mkdir /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        git clone https://www.github.com/$str_GitHub_Repo

    fi
    #

    # check for zram-swap #
    if [[ -z $str_file2 ]]; then
        cd /root/git/$str_GitHub_Repo
        sh ./install.sh
    fi
    #

    # disable ZRAM swap #
    if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then sudo swapoff /dev/zram*; fi
    #
    
    # backup config file #
    if [[ -z $str_file2"_old" ]]; then cp $str_file2 $str_file2"_old"; fi
    #

    # find HugePage size #
    str_HugePageSize="1G"

    if [[ $str_HugePageSize == "2M" ]]; then declare -i int_HugePageSizeK=2048; fi

    if [[ $str_HugePageSize == "1G" ]]; then declare -i int_HugePageSizeK=1048576; fi
    #

    # find free memory #
    declare -i int_HostMemMaxG=$((int_HostMemMaxK/1048576))
    declare -i int_SysMemMaxG=$((int_HostMemMaxG+1))                    # use modulus?
    declare -i int_HostMemFreeG=$((int_HugePageNum*int_HugePageSizeK/1048576))
    int_HostMemFreeG=$((int_SysMemMaxG-int_HostMemFreeG))
    declare -i int_ZRAM_SizeG=0
    #

    # setup ZRAM #
    if [[ $int_HostMemFreeG -le 8 ]]; then int_ZRAM_SizeG=4
    else nt_ZRAM_SizeG=$int_SysMemMaxG/2; fi

    declare -i int_denominator=$int_SysMemMaxG/$int_ZRAM_SizeG
    #str_input_ZRAM="_zram_fixedsize=\"${int_ZRAM_SizeG}G\""
    #

    # file 3
    declare -a arr_file_ZRAM=(
"# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)
# default: lz4
_zram_algorithm=\"lz4\"

# portion of system ram to use as zram swap (expression: \"1/2\", \"2/3\", \"0.5\", etc)
# default: \"1/2\"
_zram_fraction=\"1/$int_denominator\"

# setting _zram_swap_debugging to any non-zero value enables debugging
# default: undefined
#_zram_swap_debugging=\"beep boop\"

# expected compression factor; set this by hand if your compression results are
# drastically different from the estimates below
#
# Note: These are the defaults coded into /usr/local/sbin/zram-swap.sh; don't alter
#       these values, use the override variable '_comp_factor' below.
#
# defaults if otherwise unset:
#       lzo*|zstd)  _comp_factor=\"3\"   ;; # expect 3:1 compression from lzo*, zstd
#       lz4)        _comp_factor=\"2.5\" ;; # expect 2.5:1 compression from lz4
#       *)          _comp_factor=\"2\"   ;; # default to 2:1 for everything else
#
#_comp_factor=\"2.5\"

# if set skip device size calculation and create a fixed-size swap device
# (size, in MiB/GiB, eg: \"250M\" \"500M\" \"1.5G\" \"2G\" \"6G\" etc.)
#
# Note: this is the swap device size before compression, real memory use will
#       depend on compression results, a 2-3x reduction is typical
#
#_zram_fixedsize=\"4G\"

# vim:ft=sh:ts=2:sts=2:sw=2:et:"
)
    #

    # write to file #
    rm $str_file2
    for str_line in ${arr_file_ZRAM[@]}; do
        echo -e $str_line >> $str_file2
    done
    #
    
    systemctl restart zram-swap     # restart service

}

########## end ZRAM ##########

########## main ##########

Prompts

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
######### end main ##########
