#!/bin/bash

########## README ##########

# TODO:
#   StaticSetup
#   prompt user to install/execute Auto-Xorg.
#   setup input parameter passthrough
#
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
    str_input1=$str5
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

    if [[ $str_input == "N" ]]; then
    
        echo "$0: Skipping HugePages..."
        return 0;

    fi

    if [[ -z $str_input1 || $str_input1 == "Y" ]]; then echo -e $str_prompt; fi

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

    ## first input ##
    str1=$1
    str2=$2
    str3=$3
    str4=$4
    str5=$5
    str6=$6
    str7=$7
    echo "$0: \$str1 == '$str1'"          # multiboot/static          [Y/B or N/S]
    echo "$0: \$str2 == '$str2'"          # M-B: passthru given VGA   [Y/N]
    echo "$0: \$str3 == '$str3'"          # enable Evdev              [Y/E or N]
    echo "$0: \$str4 == '$str4'"          # enable Zram               [Y/Z or N]
    echo "$0: \$str5 == '$str5'"          # enable hugepages          [Y/H or N]
    echo "$0: \$str6 == '$str6'"          # set size                  [2M or 1G]
    echo "$0: \$str7 == '$str7'"          # set num                   [min or max]

    echo -e

    # example:              sudo bash $0 b e z h 1g 24 n
    # example:              sudo bash $0 b y y y 1g 24
    # example:              sudo bash $0 b n n n
    # example:              sudo bash $0 b n n n 1g 24 n

    # shift back first input if first input is NULL #
    str7=`echo $str7 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str7 ]]; then str7=$str6; fi

    str6=`echo $str6 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str6 ]]; then str6=$str5; fi

    str5=`echo $str5 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str5 ]]; then str5=$str4; fi

    str4=`echo $str4 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str4 ]]; then str4=$str3; fi

    str3=`echo $str2 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str2 ]]; then str3=$str2; fi

    str2=`echo $str2 | tr '[:lower:]' '[:upper:]'`
    if [[ -z $str2 ]]; then str2=$str1; fi
    #
    ##

    # parameters #
    str_input1=$str1
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically.\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice.\n"

    if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

    while [[ $str_input1 != "B" && $str_input1 != "S" && $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="B"                   # default selection
        
        else

            echo -en "$0: Setup VFIO?\t[ Multi-(B)oot / (S)tatic ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y"|"B")
                echo "$0: Continuing with Multi-Boot setup..."
                HugePages $str5 $str6 $str7 $str_GRUB_CMDLINE_Hugepages
                MultiBootSetup $str2 $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                #StaticSetup $str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID $arr_VGAIndex $arr_VGAVendorBusID $arr_VGAVendorDriver $arr_VGAVendorHWID $arr_VGAVendorIndex
                break;;

            "N"|"S")
                echo "$0: Continuing with Static setup..."
                HugePages $str5 $str6 $str7 $str_GRUB_CMDLINE_Hugepages
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
# NOTE: function needs work before testing

function MultiBootSetup {

    echo -e ""

    # parameters #
    str_input1=$str2
    #

    # prompt #
    declare -i int_count=0      # reset counter
    str_prompt="$0: Do you wish to review each VGA device before creating a GRUB menu entry?\n\tIn other words, do you wish to passthrough given VGA device(s), but not all?\n\tIf you are confused, please refer to the README for clarification.\n"

    if [[ -z $str_input1 || $str_input1 != "Y" && $str_input1 != "N" ]]; then echo -e $str_prompt; fi

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Review each VGA device (and intermittently pause Multi-Boot setup), or Automate Multi-Boot setup?\t[Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y")
                echo "$0: Reviewing each VGA device..."
                break;;

            "N")
                echo "$0: Automating Multi-Boot setup..."
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
    str_file1="/etc/grub.d/proxifiedScripts/custom"
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

            ### setup Boot menu entry ###

            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID"
            #

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

                for element in ${arr_file_customGRUB[@]}; do
                    echo -e $element >> $str_file1
                done
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

                for element in ${arr_file_customGRUB[@]}; do
                    echo -e $element >> $str_file1
                done
                #
            done
            ##
        fi
        #
    done
    # end parse list of VGA devices #
    ## end parse GRUB menu entries ##

    sudo update-grub    # update GRUB for good measure

}

########## end MultiBootSetup ##########

########## main ##########

Prompts $1 $2 $3 $4 $5 $6 $7

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
########## end main ##########
