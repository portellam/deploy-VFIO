#!/bin/bash

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

function ParsePCI {

    # parameters #
    str_CPUbusID="00:00.0"
    str_thisPCIBusID=""
    str_prevPCIBusID=""
    #

    # lists #
    declare -a arr_lspci=`lspci | grep ":00."`      # Bus ID
    declare -a arr_lspci_k=`lspci -k`               # Driver
    declare -a arr_lspci_n=`lspci -n | grep ":00."` # HW ID
    #
    declare -a arr_PCIBusID=""
    declare -a arr_PCIHWID=""
    declare -a arr_PCIDriver=""
    declare -a arr_PCIInfo=""
    declare -a arr_VGABusID=""
    declare -a arr_VGADriver=""
    declare -a arr_VGAHWID=""
    declare -a arr_VGAVendorBusID=""
    declare -a arr_VGAVendorDriver=""
    declare -a arr_VGAVendorHWID=""
    #

    # find external PCI device Index values, Bus ID, and drivers ##
    bool_parsePCI=false
    bool_parseVGA=false
    bool_parseVGAVendor=false
    declare -i int_index=0
    #

    # parse list of PCI devices #
    for str_line in $arr_lspci_k; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        # parse external PCI devices #
        if [[ $bool_parsePCI == true ]]; then

            if [[ $str_line != *"Subsystem: "* && $str_line != *"Kernel driver in use: "* && $str_line != *"Kernel modules: "* ]]; then     # line includes PCI bus ID

                ((int_index++))                     # increment only if Bus ID is found
                arr_PCIInfo+=($str_line)            # add line to list
                str_thisPCIBusID=(${str_line:0:7})  # raw VGA Bus ID
                # ab:cd.e   > b:d:e
                str_thisPCIBusID=${str_thisPCIBusID:1:2}${str_thisPCIBusID:4:3}                                             # ab:cd.e   > b:d.e
                str_thisPCIBusID=$(echo $str_thisPCIBusID | cut -d '.' -f 1)":"$(echo $str_thisPCIBusID | cut -d '.' -f 2)  # b:d.e     > b:d:e

                # match VGA device #
                if [[ $str_line == *"VGA"* ]]; then
            
                    arr_VGABusID+=($str_thisPCIBusID)
                    str_prevPCIBusID=($str_thisPCIBusID)
                    bool_parseVGA=true

                fi
                #

                # match VGA vendor device (Audio, USB3, etc.) #
                if [[ ${str_thisPCIBusID:0:3} == ${str_prevPCIBusID:0:3} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then

                    arr_VGAVendorBusID+=($str_thisPCIBusID)
                    bool_parseVGAVendor=true

                fi
                #

                # no match #
                if [[ $bool_parseVGA == false && $bool_parseVGAVendor == false ]]; then arr_PCIBusID+=($str_thisPCIBusID); fi
                #

            fi

            # add to list only if driver is found #
            if [[ $str_line == *"Kernel driver in use: "* ]]; then      # line includes PCI driver

                declare -i int_offset=${#str_line}-22
                str_thisPCIDriver=${str_line:23:$int_offset}

                # match VGA device #
                if [[ $bool_parseVGA == true ]]; then arr_VGADriver+=($str_thisPCIDriver); fi
                #

                # match VGA vendor device #
                if [[ $bool_parseVGAVendor == true ]]; then arr_VGAVendorDriver+=("$str_thisPCIDriver"); fi
                #

                # no match #
                if [[ $bool_parseVGA == false && $bool_parseVGAVendor == false ]]; then arr_PCIDriver+=($str_thisPCIDriver); fi
                #

                bool_parseVGA=false
                bool_parseVGAVendor=false

            fi
            #

        fi
        #

    done
    #

    # find external PCI Hardware IDs #
    bool_parseVGAVendor=false
    declare -i int_index=0

    # parse list of PCI devices #
    for str_line in $arr_lspci_n; do

        if [[ ${str_line:0:7} == "01:00.0" ]]; then bool_parsePCI=true; fi

        # parse external PCI devices ##
        if [[ $bool_parsePCI == true ]]; then 

            arr_PCIInfo+=($str_line)            # add line to list
            str_thisPCIBusID=(${str_line:0:7})  # raw VGA Bus ID
            # ab:cd.e   > b:d:e
            str_thisPCIBusID=${str_thisPCIBusID:1:2}${str_thisPCIBusID:4:3}                                            # ab:cd.e   > b:d.e
            str_thisPCIBusID=$(echo $str_thisPCIBusID | cut -d '.' -f 1)":"$(echo $str_thisPCIBusID | cut -d '.' -f 2)  # b:d.e     > b:d:e
            str_thisPCIHWID=(${str_line:14:9})

            # add to list only if VGA device #
            if [[ ${arr_PCIInfo[$int_index]} == *"VGA"* ]]; then
            
                arr_VGAHWID+=($str_thisPCIHWID)
                str_prevPCIBusID=($str_thisPCIBusID)
                
            fi
            #

            # add to lists only if VGA vendor device #
            if [[ ${str_thisPCIBusID:0:3} == ${str_prevPCIBusID:0:3} && $str_thisPCIBusID != $str_prevPCIBusID ]]; then arr_VGAVendorHWID+=($str_thisPCIHWID); fi
            #

            # add to list #
            if [[ ${arr_PCIInfo[$int_index]} != *"VGA"* && ${str_thisPCIBusID:0:3} != ${str_prevPCIBusID:0:3} ]]; then arr_PCIHWID+=($str_thisPCIHWID); fi
            #

            ((int_index++))     # increment only if match is found

        fi
        #

    done
    #

    # debug #
    function ParsePCIDebug {

        echo -e "arr_PCIBusID:\t\t${#arr_PCIBusID[@]}$"
        for element in ${arr_PCIBusID[@]}; do
            echo -e "PCIBusID:\t\t"$element
        done

        echo -e "arr_VGABusID:\t\t${#arr_VGABusID[@]}$"
        for element in ${arr_VGABusID[@]}; do
            echo -e "arr_VGABusID:\t\t"$element
        done

        echo -e "arr_VGAVendorBusID:\t${#arr_VGAVendorBusID[@]}$"
        for element in ${arr_VGAVendorBusID[@]}; do
            echo -e "arr_VGAVendorBusID:\t"$element
        done

        echo -e "arr_PCIDriver:\t\t${#arr_PCIDriver[@]}$"
        for element in ${arr_PCIDriver[@]}; do
            echo -e "PCIDriver:\t\t"$element
        done

        echo -e "arr_VGADriver:\t\t${#arr_VGADriver[@]}$"
        for element in ${arr_VGADriver[@]}; do
            echo -e "arr_VGADriver:\t\t"$element
        done

        echo -e "arr_VGAVendorDriver:\t${#arr_VGAVendorDriver[@]}$"
        for element in ${arr_VGAVendorDriver[@]}; do
            echo -e "arr_VGAVendorDriver:\t"$element
        done

        echo -e "arr_PCIHWID:\t\t${#arr_PCIHWID[@]}$"
        for element in ${arr_PCIHWID[@]}; do
            echo -e "PCIHWID:\t\t"$element
        done

        echo -e "arr_VGAHWID:\t\t${#arr_VGAHWID[@]}$"
        for element in ${arr_VGAHWID[@]}; do
            echo -e "arr_VGAHWID:\t\t"$element
        done

        echo -e "arr_VGAVendorHWID:\t${#arr_VGAVendorHWID[@]}$"
        for element in ${arr_VGAVendorHWID[@]}; do
            echo -e "arr_VGAVendorHWID:\t"$element
        done

    }
    #

    # debug #
    ParsePCIDebug
    #

}

ParsePCI

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
