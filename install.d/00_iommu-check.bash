#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# precede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {
        echo -en "$0: $str_output1"

        if [[ $str_input1 == "Y" ]]; then
            echo -en $str_output1$str_input1
        else
            declare -i int_count=0      # reset counter

            while true; do
                # manual prompt #
                if [[ $int_count -ge 3 ]]; then       # auto answer
                    echo "Exceeded max attempts."
                    str_input1="N"                    # default input     # NOTE: change here
                else
                    echo -en $str_output1
                    read str_input1

                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                    str_input1=${str_input1:0:1}
                fi

                case $str_input1 in
                    "Y"|"N")
                        break;;
                    *)
                        echo -en "$0: Invalid input. ";;
                esac

                ((int_count++))         # increment counter
            done
        fi
    }

# parameters #
    bool_dev_isVFIO=false

# GRUB and hugepages check #
    if [[ -z $str_logFile0 ]]; then
        echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_logFile0' and '$0'.\n"
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="
    else
        str_GRUB_CMDLINE_Hugepages=`cat $str_logFile0`
    fi

    str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages"

# shell option #
    shopt -s nullglob

# catalog devices in each IOMMU group #
    function ParsePCI
    {
        # parameters #
            arr_IOMMU_sum=(`find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`)

        # parse IOMMU groups #
            for str_line1 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
            # for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do

                # parameters #
                    # str_line1=${arr_IOMMU_sum[$int_i]}
                    str_input1=""
                    int_IOMMU=`echo $str_line1 | cut -d '/' -f5`
                    bool_dev_isExt=false
                    bool_dev_isVGA=false

                # prompt #
                    echo -e "\n\tIOMMU :\t\t${int_IOMMU##*/}"

                # parse devices #
                    for int_i in $str_line1/devices/*; do

                        # parameters #
                            str_thisIOMMU=`lspci -nnks ${int_i##*/} | grep -Eiv 'devicename|module|subsystem'`
                            str_devBusID=`lspci -s ${int_i##*/} | cut -d ' ' -f1`
                            str_devDriver=`lspci -nnks ${int_i##*/} | grep 'driver' | cut -d ':' -f2 | cut -d ' ' -f2`
                            str_devHWID=`lspci -ns ${int_i##*/} | cut -d ' ' -f3`
                            str_devName=`lspci -ms ${int_i##*/} | cut -d '"' -f6`
                            str_devType=`lspci -ms ${int_i##*/} | cut -d '"' -f2`

                        # false match driver, prompt user this info #
                            if [[ -z $str_devDriver ]]; then
                                str_devDriver="NULL"
                            fi

                        # match vfio, set boolean #
                            if [[ $str_devDriver == *"vfio-pci"* ]]; then
                                bool_dev_isVFIO=true
                            fi

                        # false match name #
                            if [[ -z $str_devName ]]; then
                                str_devName="NULL"
                            fi

                        # lists #
                            arr_devIndex_sum+=($int_i)
                            arr_devDriver_sum+=($str_devDriver)
                            arr_devHWID_sum+=($str_devHWID)
                            arr_devName_sum+=($str_devName)

                        # prompt #
                            # echo -e "\t$str_thisIOMMU"
                            echo
                            echo -e "\tBUS ID:\t\t$str_devBusID"
                            #echo -e "\tVENDOR:\t\t${arr_vendorName_sum[$int_i]}"
                            echo -e "\tNAME  :\t\t$str_devName"
                            echo -e "\tTYPE  :\t\t$str_devType"
                            echo -e "\tHW ID :\t\t$str_devHWID"
                            echo -e "\tDRIVER:\t\t$str_devDriver"

                        # update parameters #
                            str_devBusID=`echo $str_devBusID | cut -d ':' -f1`
                            str_devType=`echo $str_devType | tr '[:lower:]' '[:upper:]'`

                        # checks #
                            if [[ $str_devType == *'VGA'* || $str_devType == *'GRAPHICS'* ]]; then
                                bool_dev_isVGA=true
                            fi

                            if [[ ${str_devBusID:1} != 0 || ${str_devBusID::2} -gt 0 ]]; then
                                bool_dev_isExt=true
                            fi

                            if [[ ${str_devBusID_sum:0:1} == "0" && ${str_devBusID:1} -eq 0 ]]; then
                                bool_dev_isExt=true
                            fi
                    done;

                # prompt #
                    if [[ $bool_dev_isExt == true ]]; then
                        echo
                        str_output1="Select IOMMU group '$int_IOMMU'? [Y/n]: "
                        ReadInput $str_output1

                        if [[ $bool_dev_isVGA == false ]]; then
                            case $str_input1 in
                                "Y")
                                    arr_IOMMU_VFIO+=($int_IOMMU)
                                    echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                "N")
                                    arr_IOMMU_host+=($int_IOMMU);;
                                *)
                                    echo -en "$0: Invalid input.";;
                            esac
                        else
                            case $str_input1 in
                                "Y")
                                    arr_IOMMU_VGA_VFIO+=($int_IOMMU)
                                    echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                "N")
                                    arr_IOMMU_VGA_host+=($int_IOMMU);;
                                *)
                                    echo -en "$0: Invalid input.";;
                            esac
                        fi
                    else
                        echo -e "\n$0: Skipped IOMMU group '$int_IOMMU'."
                    fi
            done

        # debug prompt #
            # uncomment lines below #
            function DebugOutput {
                echo -e "$0: ========== DEBUG PROMPT ==========\n"

                for (( i=0 ; i<${#arr_devIndex_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIndex_sum[$i]}'\t= ${arr_devIndex_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_devDriver_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devDriver_sum[$i]}'\t= ${arr_devDriver_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_devHWID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devHWID_sum[$i]}'\t= ${arr_devHWID_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_devName_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devName_sum[$i]}'\t= ${arr_devName_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_driver_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_driver_VFIO[$i]}'\t= ${arr_driver_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_HWID_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_HWID_VFIO[$i]}'\t= ${arr_HWID_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO[$i]}'\t= ${arr_IOMMU_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host[$i]}'\t= ${arr_IOMMU_host[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VGA_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_VFIO[$i]}'\t= ${arr_IOMMU_VGA_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VGA_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_host[$i]}'\t= ${arr_IOMMU_VGA_host[$i]}"; done && echo


                echo -e "$0: '$""{#arr_devIndex_sum[@]}'\t= ${#arr_devIndex_sum[@]}"
                echo -e "$0: '$""{#arr_devDriver_sum[@]}'\t= ${#arr_devDriver_sum[@]}"
                echo -e "$0: '$""{#arr_devHWID_sum[@]}'\t= ${#arr_devHWID_sum[@]}"
                echo -e "$0: '$""{#arr_devName_sum[@]}'\t= ${#arr_devName_sum[@]}"
                echo -e "$0: '$""{#arr_driver_VFIO[@]}'\t= ${#arr_driver_VFIO[@]}"
                echo -e "$0: '$""{#arr_HWID_VFIO[@]}'\t= ${#arr_HWID_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VFIO[@]}'\t= ${#arr_IOMMU_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_host[@]}'\t= ${#arr_IOMMU_host[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VGA_VFIO[@]}'= ${#arr_IOMMU_VGA_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VGA_host[@]}'= ${#arr_IOMMU_VGA_host[@]}"

                echo -e "\n$0: ========== DEBUG PROMPT =========="
                exit 0
            }

        DebugOutput    # uncomment to debug here
    }



# call functions #
    ParsePCI

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0