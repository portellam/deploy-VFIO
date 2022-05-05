#!/bin/bash

    ### set IFS ##
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char
    ###

    str_CPUbusID="00:00.0"
    declare -a arr_PCIdevBusID
    declare -a arr_PCIdevDriver
    declare -a arr_PCIdevHWID
    declare -a arr_PCIdevInfo
    declare -a arr_PCIdevIndex
    declare -a arr_VGAdevIndex

    # create log file #
    str_dir="/var/log/"
    str_file_arr_PCIinfo=$str_dir'str_file_arr_PCIinfo.log'
    str_file_arr_PCIdriver=$str_dir'arr_PCIdriver.log'
    str_file_arr_PCIHWID=$str_dir'arr_PCIhwID.log'
    #

    lspci | grep ":00." > $str_file_arr_PCIinfo
    lspci -k > $str_file_arr_PCIdriver
    lspci -n | grep ":00." > $str_file_arr_PCIHWID

    # test loop #
    # NOTE: works
    #declare -i i=0
    #while read str_line; do
        #if [[ $str_line == *":00."* && $str_line != *"00:00.0"* ]]; then 
            #echo -e $i":\t'"$str_line
        #fi
        #((i++))
    #done < $str_file_arr_PCIinfo
    #

    # find external PCI device Index values #
    # from here you can find the Hardware ID, using the same structure loop #
    # parse list of PCI devices
    bool1=false
    bool_VGA=false
    bool_VGA_SND=false
    declare -i i=0
    while read str_line; do

        #echo $str_line

        if [[ ${str_line:0:7} == "01:00.0" ]]; then
            bool1=true;
        fi

        if $bool1 == true; then

            if [[ $str_line != *"Subsystem: "* && $str_line != *"Kernel driver in use: "* && $str_line != *"Kernel modules: "* ]]; then
            
                ((i++))     # increment only if Bus ID is found
                str_thisPCIdevBusID=(${str_line:0:8})
                arr_PCIdevInfo+=($str_line)     # add line to list
                arr_PCIdevBusID+=($str_thisPCIdevBusID)   # add Bus ID index to list

                if [[ $str_line == *"VGA"* ]]; then

                    arr_VGAdevBusID+=($str_thisPCIdevBusID);
                    bool_VGA=true
                    bool_VGA_SND=true

                fi

                if [[ $bool_VGA_SND == true && $str_line == *"Audio"* ]]; then

                    arr_VGAdevBusID+=($str_thisPCIdevBusID);
                    bool_VGA_SND=false

                fi

                #echo -e $i":\t'"${str_line:0:8}

            fi
            
            if [[ $str_line == *"Kernel driver in use: "* ]]; then 
            
                declare -i int_offset=${#str_line}-22
                str_thisPCIdevDriver=${str_line:23:$int_offset}
                arr_PCIdevDriver+=($str_thisPCIdevDriver)
                #echo -e $i":\t'"${str_line:23:$int_offset}
                arr_PCIdevIndex+=("$i")     # add to list only if driver is found

                if [[ $bool_VGA == true ]]; then

                    arr_VGAdevDriver+=($str_thisPCIdevDriver);
                    bool_VGA=false

                fi
                
            fi
        fi

    done < $str_file_arr_PCIdriver
    ##

    #
    bool_VGA_SND=false
    declare -i i=0
    while read str_line; do

        if [[ $str_line == *":00."* && $str_line != *"00:00.0"* ]]; then

            str_thisPCIdevHWID=(${str_line:14:9})
            arr_PCIdevHWID+=($str_thisPCIdevHWID)
            #echo -e $i":\t'"${str_line:14:9}
            #echo ${arr_PCIdevInfo[$i]}
            if [[ ${arr_PCIdevInfo[$i]} == *"VGA"* ]]; then
            
                arr_VGAdevHWID+=($str_thisPCIdevHWID)
                bool_VGA_SND=true

            fi

            if [[ $bool_VGA_SND == true && ${arr_PCIdevInfo[$i]} == *"Audio"* ]]; then

                arr_VGAdevHWID+=($str_thisPCIdevHWID);
                bool_VGA_SND=false

            fi

            ((i++))     # increment only if match is found

        fi

    done < $str_file_arr_PCIHWID
    #

    echo "PCIdevBusID"
    for element in ${arr_PCIdevBusID[@]}; do
        echo $element
    done

    echo "arr_PCIdevDriver"
    for element in ${arr_PCIdevDriver[@]}; do
        echo $element
    done

    echo "arr_PCIdevHWID"
    for element in ${arr_PCIdevHWID[@]}; do
        echo $element
    done

    echo "arr_VGAdevBusID"
    for element in ${arr_VGAdevBusID[@]}; do
        echo $element
    done

    echo "arr_VGAdevDriver"
    for element in ${arr_VGAdevDriver[@]}; do
        echo $element
    done

    echo "arr_VGAdevHWID"
    for element in ${arr_VGAdevHWID[@]}; do
        echo $element
    done


    echo "."
    
    # all external PCI devices (with bus ID and type)
    declare -a arr_PCIinfo=`lspci | grep ":00."`
    declare -a arr_PCIinfoNew
    # delete first element
    arr_PCIinfo=( "${arr_PCIinfo[@]/$str_CPUbusID}" )
    
    #
    #for (( i=0; i<${#str_file_arr_PCIinfo[@]}; i++ )); do
    #for element in $arr_PCIinfo; do
        #echo $element
        #if [[ $element == *":00."* && $element != *"00:00.0"* ]]; then arr_PCIinfoNew+=( "$element" ); fi
    #done

    echo "."

    for element in $arr_PCIinfoNew; do
        echo $element
    done

    # all external PCI devices (with bus ID and hardware ID)
    declare -a arr_PCIhwID=( `lspci -n | grep ":00."` )
    # delete first element
    arr_PCIhwID=( "${arr_PCIhwID[@]/$str_CPUbusID}" )
    #

    #echo ${arr_PCIhwID[@]}
    #echo "."

    # all external PCI devices (with kernel driver)
    declare -a arr_PCIdriver=`lspci -k | grep "Kernel driver in use: "`
    # delete all elements before given index
    for (( int_index=0; int_index<$[${#arr_PCIdriver[@]}]; int_index++ )); do

        element=${arr_PCIdriver[$int_index]}
        if [[ $element != *"1:00.0"* ]]; then arr_PCIdriver=("${arr_PCIdriver[$int_index]/$element}");
        else break; fi

    done
    # delete all unrelated info
    for (( int_index=0; int_index<$[${#arr_PCIdriver[@]}]; int_index++ )); do

        element=${arr_PCIdriver[$int_index]}
        if [[ $element != *"Kernel driver in use: "* ]]; then arr_PCIdriver=("${arr_PCIdriver[$int_index]/$element}");
        else break; fi

    done

    #

    #echo ${arr_PCIdriver[@]}
    #echo "."

    # all external VGA devices (with bus ID)
    arr_lspci_VGA=`lspci | grep VGA`
    #

    #echo ${arr_lspci_VGA[@]}
    #echo "."

    
names="Netgear
Hon Hai Precision Ind. Co.
Apple"
    
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
names=($names) # split the `names` string into an array by the same name
IFS=$SAVEIFS   # Restore original IFS

for (( i=0; i<${#names[@]}; i++ ))
do
    echo "$i: ${names[$i]}"
done


### reset IFS ##
    IFS=$SAVEIFS   # Restore original IFS
##

exit 0
