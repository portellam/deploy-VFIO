#!/bin/bash

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

function ParsePCI {

# parameters #
declare -a arr_PCIBusID
declare -a arr_PCIDriver
declare -a arr_PCIHWID
declare -a arr_VGABusID
declare -a arr_VGADriver
declare -a arr_VGAHWID
declare -a arr_VGAVendorBusID
declare -a arr_VGAVendorDriver
declare -a arr_VGAVendorHWID
bool_parseA=false
bool_parseB=false
bool_parseVGA=false
bool_parseVGAVendor=false
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
    if [[ ${str_line1:0:7} == *"01:00.0"* ]]; then bool_parseA=true; fi

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
        for (( int_indexB=0; int_indexB<${#arr_lspci_k[@]}; int_indexB++ )); do
            
            str_line2=${arr_lspci_k[$int_indexB]}    # element    

            # begin parse #
            if [[ ${str_line2:0:7} == *"01:00.0"* ]]; then bool_parseB=true; fi
            #

            # parse #
            if [[ $bool_parseB == true ]]; then
                # match VGA #
                if [[ $str_line2 == *"VGA"* ]]; then bool_parseVGA=true; fi
                #

                # match VGA Vendor #
                if [[ $str_line2 != *"VGA"* && $str_prevLine2 == *"$str_thisPCIVendor"* ]]; then bool_parseVGAVendor=true; fi
                #
            fi
            #

            if [[ $bool_parseB == true && $str_line2 != *"vfio-pci"* && $str_line2 == *"Kernel driver in use: "* && $str_line2 != *"Subsystem: "* && $str_line2 != *"Kernel modules: "* ]]; then

                str_thisPCIDriver=`echo $str_line2 | cut -d " " -f 5`   # PCI driver
                echo "str_thisPCIDriver == '$str_thisPCIDriver'"
                arr_PCIDriver+=("$str_PCIDriver")                       # add to list

                # match VGA, add to list #
                if [[ $bool_parseVGA == true ]]; then
                    arr_thisVGADriver+=("$str_PCIDriver")
                fi

                # match VGA, add to list #
                if [[ $bool_parseVGAVendor == true ]]; then
                    arr_thisVGAVendorDriver+=("$str_thisPCIDriver")
                fi

                int_indexB=${#arr_lspci_k[@]}   # break loop
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

#
        echo -e "arr_PCIBusID == ${#arr_PCIBusID[@]}i"
        for element in ${arr_PCIBusID[@]}; do
            echo -e "PCIBusID == "$element
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
            echo -e "PCIDriver == "$element
        done

        echo -e "arr_VGADriver == ${#arr_VGADriver[@]}i"
        for element in ${arr_VGADriver[@]}; do
            echo -e "arr_VGADriver == "$element
        done

        echo -e "arr_VGAVendorDriver == ${#arr_VGAVendorDriver[@]}i"
        for element in ${arr_VGAVendorDriver[@]}; do
            echo -e "arr_VGAVendorDriver == "$element
        done

        echo -e "arr_PCIHWID == ${#arr_PCIHWID[@]}i"
        for element in ${arr_PCIHWID[@]}; do
            echo -e "PCIHWID == "$element
        done

        echo -e "arr_VGAHWID == ${#arr_VGAHWID[@]}i"
        for element in ${arr_VGAHWID[@]}; do
            echo -e "arr_VGAHWID == "$element
        done

        echo -e "arr_VGAVendorHWID == ${#arr_VGAVendorHWID[@]}i"
        for element in ${arr_VGAVendorHWID[@]}; do
            echo -e "arr_VGAVendorHWID == "$element
        done
#

}

ParsePCI

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
