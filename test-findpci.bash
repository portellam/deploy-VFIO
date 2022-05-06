#!/bin/bash

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# methods start #

function 01_VFIO_PCI {

    echo "VFIO_PCI: Start."

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
    str_dir="/var/log/"
    #str_dir="/dev/tmp/"
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
    while read str_line; do

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
    while read str_line; do

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

    VFIO_PCI_DEBUG

    # remove log files #
    rm $str_file_arr_PCIInfo $str_file_arr_PCIDriver $str_file_arr_PCIHWID
    #

    echo "VFIO_PCI: End."

}

# methods end #

# main start #

echo "Main: Start."

01_VFIO_PCI

# reset IFS #
    IFS=$SAVEIFS   # Restore original IFS
#

echo "Main: End."

exit 0

# main end
