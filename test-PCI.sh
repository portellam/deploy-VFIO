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
    declare -a arr_lspci=`lspci`        # Bus ID
    declare -a arr_lspci_k=`lspci -k`   # Driver
    declare -a arr_lspci_m=`lspci -m`   # machine readable
    declare -a arr_lspci_n=`lspci -n`   # HW ID
    #
    declare -a arr_PCIBusID
    declare -a arr_PCIHWID
    declare -a arr_PCIDriver
    declare -a arr_PCIInfo
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    declare -a arr_VGAHWID
    declare -a arr_VGAVendorBusID
    declare -a arr_VGAVendorDriver
    declare -a arr_VGAVendorHWID
    #

    # find external PCI device Index values, Bus ID, and drivers ##
    bool_parsePCI=false
    bool_parseVGA=false
    bool_parseVGAVendor=false
    declare -i int_index=0
    #

        # save for Xorg
            # convert raw string to copy readable by Xorg
            # ab:cd.e   > b:d:e
            #str_thisPCIBusID=${str_thisPCIBusID:1:2}${str_thisPCIBusID:4:3}                                             # ab:cd.e   > b:d.e
            #str_thisPCIBusID=$(echo $str_thisPCIBusID | cut -d '.' -f 1)":"$(echo $str_thisPCIBusID | cut -d '.' -f 2)  # b:d.e     > b:d:e
        #


    ## NEW BELOW ##

    for str_line1 in $arr_lspci_m; do

        # save Info #
        str_thisPCIBusID=(${str_line1:0:7})                     # raw Bus ID    (example AB:CD.E)
        str_somePCIBusID=`$str_thisPCIBusID | cut -d "." -f 1`  # truncated ID  (example AB:CD)
        echo "str_somePCIBusID == $str_somePCIBusID"
        str_thisPCIType=`$str_line1 | cut -d '"' -f 2`          # Type          (example VGA)
        echo "str_thisPCIType == $str_thisPCIType"
        str_thisPCIVendor=`$str_line1 | cut -d '"' -f 4`        # Vendor name   (example NVIDIA)
        echo "str_thisPCIVendor == $str_thisPCIVendor"
        #

        arr_PCIBusID+=("$str_thisPCIBusID")                     # add to list

        # match VGA device #
        if [[ $str_line1 == *"VGA"* ]]; then
        
            # convert raw string to copy readable by Xorg
            # ab:cd.e   > b:d:e
            str_thisVGABusID=${str_thisPCIBusID:1:2}${str_thisPCIBusID:4:3}
            echo "str_thisVGABusID == $str_thisVGABusID"
            # b:d.e     > b:d:e
            str_thisVGABusID=$(echo $str_thisPCIBusID | cut -d '.' -f 1)":"$(echo $str_thisPCIBusID | cut -d '.' -f 2)
            echo "str_thisVGABusID == $str_thisVGABusID"
            arr_VGABusID+=("$str_thisVGABusID")
        
        fi
        #

        # match VGA Vendor from last line #
        # NOTE: non VGA devices may also have multiple interfaces (?), but that is irrelevant for the objective here.
        # Objective: list all PCI devices, and VGA and VGA Vendor devices.
        if [[ $str_line1 != *"VGA"* && $str_prevLine1 == *"$str_thisPCIVendor"* ]]; then arr_VGAVendorBusID+=("$str_thisPCIBusID"); fi
        #

        # parse HW IDs #
        for str_line2 in $arr_lspci_n; do

            str_thisPCIHWID=(${str_line2:14:9})             # Hardware ID

            # match Bus ID
            if [[ $str_thisPCIBusID == ${str_line2:0:7} ]]; then

                arr_PCIHWID+=("$str_thisPCIHWID")           # add to list

                # match VGA device #
                if [[ $str_line1 == *"VGA"* ]]; then arr_VGAHWID+=("$str_thisPCIHWID"); fi    # add to list
                #

                # match VGA Vendor from last line #
                if [[ $str_line1 != *"VGA"* && $str_prevLine1 == *"$str_somePCIBusID"* && $str_prevLine1 == *"$str_thisPCIVendor"* ]]; then arr_VGAVendorHWID+=("$str_thisPCIHWID"); fi        # add to list
                #
            fi
            #
        done
        #

        # parse Drivers #
        for str_line3 in $arr_lspci_k; do

            # match Bus ID
            if [[ $str_thisPCIBusID == ${str_line3:0:7} ]]; then

                arr_PCIDriver+=("$str_thisPCIDriver")                           # add to list

                # match VGA device #
                if [[ $str_line1 == *"VGA"* ]]; then bool_parseVGA=true; fi     # add to list
                #

                # match VGA Vendor from last line #
                if [[ $str_line1 != *"VGA"* && $str_prevLine1 == *"$str_somePCIBusID"* && $str_prevLine1 == *"$str_thisPCIVendor"* ]]; then bool_parseVGAVendor=true; fi         # add to list
                #  
            fi
            #

            # before next Bus ID, match Driver
            if [[ $str_line3 == *"Kernel driver in use: "* ]]; then

                declare -i int_offset=${#str_line}-22
                str_thisPCIDriver=${str_line:23:$int_offset}
                arr_PCIDriver+=("$str_thisPCIDriver")               # add to list

                # match VGA device #
                if [[ $bool_parseVGA == true ]]; then
                    arr_VGADriver+=("$str_thisPCIDriver")           # add to list
                    bool_parseVGA=false
                fi
                #

                # match VGA Vendor from last line #
                if [[ $bool_parseVGAVendor == true ]]; then
                    arr_VGAVendorDriver+=("$str_thisPCIDriver")     # add to list
                    bool_parseVGAVendor=false
                fi
                #
            fi
            #
        done
        #

        str_prevLine1=$str_line1    # save previous line for comparison

    done
    #

    ## NEW ABOVE ##

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
    #ParsePCIDebug
    #

}

ParsePCI

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
