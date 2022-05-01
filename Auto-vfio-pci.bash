#!/bin/bash

## METHODS start ##

function 01_FindPCI {
    
    echo "FindPCI: Start."

    ## PARAMETERS ##
    bool_foundFirstVGA=false
    bool_isMatch=false
    bool_isVGA=false
    bool_read=false
    int_count=0
    # CREATE LOG FILE #
    str_dir="/var/log/"
    str_file_1=$str_file'lspci_n.log'
    str_file_2=$str_file'lspci.log'
    str_file_3=$str_file'lspci_k.log'
    lspci -n > $str_file_1
    lspci > $str_file_2
    lspci -k > $str_file_3
    #
    str_first_PCIbusID="01.00.0"
    str_PCIbusID=""
    str_PCIdriver=""
    str_PCIhwID=""
    str_PCItype=""
    str_xorg_PCIbusID=""
    str_xorg_PCIdriver=""
    declare -a arr_PCIbusID=()
    declare -a arr_PCIdriver=()
    declare -a arr_PCIhwID=()
    
    # FILE_1 #
    # PARSE FILE AND SAVE TO ARRAY
    while read str_line_1; do
        
        str_PCIbusID=${str_line_1:1:7}
        
        # START READ FROM FIRST EXTERNAL PCI
        if [[ $str_PCIbusID -eq $str_first_PCIbusID ]]; then
                
            bool_read=true
            
        fi
        
        # SAVE PCI HARDWARE ID
        if [[ $bool_read ]]; then
        
            str_PCIhwID=$(echo ${str_line_1:14:8})
            arr_PCIbusID+=("$PCIbusID")

        fi

    done < $str_file_1
    # FILE 1 END #
                
    # FILE 3 #
    # VFIO SETUP (FIRST-TIME):  PARSE FILE, CHECK FOR PCI MATCH, SAVE EACH PCI HW ID, AND SAVE EACH NON VFIO-PCI DRIVER
    # XORG SETUP (CONSECUTIVE): PARSE FILE, CHECK FOR PCI MATCH, SAVE EACH PCI VGA BUS ID, NON VFIO-PCI VGA DRIVER (COPY AND CREATE ON DIFFERENT SCRIPT FILE)
    while read str_line_3; do

        # FILE 2 #
        # PARSE FILE AND CHECK FOR VGA MATCH
        while read str_line_2; do
    
            # LENGTH OF ARRAY
            int_arr_PCIbusID=${#arr_PCIbusID[@]} 

            # PARSE ARRAY
            for (( int_index=0; int_index<$int_arr_PCIbusID; int_index++ )); do

                # VALIDATE PCI BUS ID
                if [[ $arr_PCIbusID[$int_index] -eq ${str_line_2:1:7} ]]; then
        
                    #str_PCItype=$(echo ${str_line_2:8:50} | cut -d ":" -f1)    # OLD
                    str_PCItype=$(echo ${str_line_2:8:3} )

                    # CHECK IF PCI IS VGA
                    #if [[ $str_PCItype -eq "VGA compatible controller" ]]; then    # OLD
                    if [[ $str_PCItype -eq "VGA" ]]; then

                        bool_isVGA=true
                
                    fi

                fi
        
            done

        done < $str_file_2
        # FILE 2 END #
                            
        # VALIDATE PCI BUS ID
        if [[ $str_PCIbusID -eq ${str_line_3:1:7} ]]; then
                                
            bool_isMatch=true
                                
        fi         
        
        # VALIDATE STRING FOR PCI DRIVER
        if [[ $bool_isMatch && $str_line_3 -eq *"Kernel driver in use: "* && $str_line_3 -ne *"Subsystem: "* && $str_line_3 -ne *"Kernel modules: "* ]]; then
                                                                    
            int_len_str_line_3=${#str_line_3}-22
            str_PCIdriver=${str_line_3:22:$int_len_str_line_3}
                                    
            

            # SAVE EVERY EXTERNAL PCI DEVICE
            if [[ $str_PCIdriver -ne "vfio-pci" ]]; then

                echo "FindPCI: str_PCIdriver: \"$str_PCIdriver\""
                echo "FindPCI: str_PCIhwID: \"$str_PCIhwID\"" 
                arr_PCIdriver+=("$str_PCIdriver")
                arr_PCIhwID+=("$str_PCIhwID")
                                        
            fi


            # SAVE FIRST EXTERNAL VGA NON VFIO-PCI DEVICE
            #if [[ $bool_isVGA && $bool_foundFirstVGA -eq false && $str_PCIdriver -ne "vfio-pci" ]]; then
                                    
                #str_xorg_PCIbusID=$str_PCIbusID
                #str_xorg_PCIdriver=$str_PCIdriver
                #bool_foundFirstVGA=true
                                        
            #fi

        fi

    done < $str_file_3
    # FILE 3 END #
            
    # CLEAR LOG FILES
    rm $str_file_1 $str_file_2 $str_file_3
        
    echo "FindPCI: End."
    
}

function 02_Xorg {

    echo "Xorg: Start."

    # SET WORKING DIRECTORY
    str_dir="/etc/X11/xorg.conf.d/"

    # INIT FILE
    str_file=$str_dir"10-"$str_xorg_PCIdriver".conf"
    
    # CLEAR FILES
    rm $str_dir"10-"*".conf"
    
    # PARAMETERS
    declare -a arr_Xorg=(
"Section "Device"
Identifier     "Device0"
Driver         "$str_xorg_PCIdriver"
BusID          "PCI:$str_xorg_PCIbusID"
EndSection
"
)

    # ARRAY LENGTH
    int_sources=${#arr_sources[@]}
    
    # WRITE ARRAY TO FILE
    for (( int_index=0; int_index<$int_sources; int_index++ )); do
    
        str_line=${arr_Xorg[$int_index]}
        echo $str_line >> $str_file
        
    done

    # FIND PRIMARY DISPLAY MANAGER
    #$str_line=$(cat /etc/X11/default-display-manager)
    #str_DM=${str_line:8:(${#str_line}-9)}

    # RESTART DM
    #systemctl restart $str_DM

    echo "Xorg: End."

}

## METHODS end ##

## MAIN start ##

echo "MAIN: Start."

# SHARED PARAMETERS #
#str_xorg_PCIbusID=""
#str_xorg_PCIdriver=""
declare -a arr_PCIdriver=()
declare -a arr_PCIhwID=()
#

# METHODS #
01_FindPCI
#echo "MAIN: str_xorg_PCIbusID: \"$str_xorg_PCIbusID\""
#echo "MAIN: str_xorg_PCIdriver: \"$str_xorg_PCIdriver\""

#02_VFIO
#03_Xorg
#

echo "MAIN: End."

## MAIN end ##

exit 0
