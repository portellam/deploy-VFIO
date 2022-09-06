#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

#
# TO-DO
# -make parity with Multi-boot setup (var names, functions, etc.)
#
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
        exit 0
    fi

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "install.d" ]]; then
        if [[ -e `find . -name install.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
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

# GRUB and hugepages check #
    str_file=`find . -name *Hugepages*log*`

    if [[ -z $str_file ]]; then
        str_file=`find . -name *Hugepages*bash*`
        str_file=`echo ${str_file##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_file' and '$0'.\n"
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="
    else
        str_GRUB_CMDLINE_Hugepages=`cat $str_file`
    fi

    str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages"

# Static setup #
    function StaticSetup {

        echo -e "$0: Executing Static setup..."

        # Parse IOMMU #
            # shell option #
                shopt -s nullglob

            # parameters #
                declare -a arr_IOMMU_sum=(`find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`)
                declare -a arr_devIndex_sum
                declare -a arr_devDriver_sum
                declare -a arr_devHWID_sum
                declare -i int_index=0

            # parse IOMMU groups #
                for str_line1 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                    # parameters #
                        bool_isExt=false
                        declare -i int_IOMMU=`echo $str_line1 | cut -d '/' -f5`
                        str_input1=""

                    # prompt #
                        echo -e "\n\tIOMMU :\t\t${int_IOMMU##*/}"

                    # parse devices #
                        for str_line2 in $str_line1/devices/*; do

                            # parameters #
                                int_thisIOMMU=`echo $str_line2 | cut -d '/' -f5`
                                str_devBusID=`lspci -s ${str_line2##*/} | cut -d ' ' -f1`
                                str_devDriver=`lspci -nnks ${str_line2##*/} | grep 'driver' | cut -d ':' -f2 | cut -d ' ' -f2`
                                str_devHWID=`lspci -ns ${str_line2##*/} | cut -d ' ' -f3`
                                str_devName=`lspci -ms ${str_line2##*/} | cut -d '"' -f6`
                                str_devType=`lspci -ms ${str_line2##*/} | cut -d '"' -f2`
                                str_devVendor=`lspci -ms ${str_line2##*/} | cut -d '"' -f4`

                            # prompt #
                                echo
                                echo -e "\tBUS ID:\t\t$str_devBusID"
                                echo -e "\tVENDOR:\t\t$str_devVendor"
                                echo -e "\tNAME  :\t\t$str_devName"
                                echo -e "\tTYPE  :\t\t$str_devType"
                                echo -e "\tHW ID :\t\t$str_devHWID"
                                echo -e "\tDRIVER:\t\t$str_devDriver"

                            # match null #
                                if [[ -z $str_devDriver ]]; then
                                    str_devDriver=""
                                fi

                            # match vfio, set boolean #
                                if [[ $str_devDriver == *"vfio-pci"* ]]; then
                                    bool_isVFIO=true
                                fi

                            # match problem driver #
                                if [[ $str_devDriver == *"snd_hda_intel"* ]]; then
                                    str_devDriver=""
                                fi

                            # lists #
                                arr_devIndex_sum+=($int_index)
                                arr_devIOMMU_sum+=($int_thisIOMMU)
                                arr_devHWID_sum+=($str_devHWID)

                                if [[ $str_devDriver != "" ]]; then
                                    arr_devDriver_sum+=($str_devDriver)
                                fi

                            # update parameters #
                                str_devBusID=`echo $str_devBusID | cut -d ':' -f1`

                            # checks #
                                # set flag for external groups #
                                if [[ ${str_devBusID:1} != 0 || ${str_devBusID::2} -gt 0 ]]; then
                                    bool_isExt=true
                                fi

                            ((int_index++))
                        done

                    # prompt #
                        if [[ $bool_isExt == true ]]; then
                            echo
                            str_output1="Select IOMMU group '$int_IOMMU'? [Y/n]: "
                            ReadInput $str_output1

                            case $str_input1 in
                                "Y")
                                    arr_IOMMU_VFIO+=("$int_IOMMU")
                                    echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                "N")
                                    arr_IOMMU_host+=("$int_IOMMU");;
                                *)
                                    echo -en "$0: Invalid input.";;
                            esac
                        else
                            echo -e "\n$0: Skipped IOMMU group '$int_IOMMU'."
                        fi
                done

            # generate output for system files #
                for int_IOMMU in ${arr_IOMMU_VFIO[@]}; do
                    for (( int_index=0 ; int_index<${#arr_devIndex_sum[@]} ; int_index++ )); do
                        int_thisIOMMU=${arr_devIOMMU_sum[$int_index]}
                        str_thisDevDriver=${arr_devDriver_sum[$int_index]}
                        str_thisDevHWID=${arr_devHWID_sum[$int_index]}

                        # match IOMMU #
                            if [[ "$int_thisIOMMU" == "$int_IOMMU" ]]; then
                                str_HWID_VFIO_list+="$str_thisDevHWID,"

                                if [[ $str_thisDevDriver != "" || $str_thisDevDriver != "NULL" ]]; then
                                    arr_driver_VFIO+=("$str_thisDevDriver")
                                    str_driver_VFIO_list+="$str_thisDevDriver,"
                                fi

                                # break;
                            fi
                    done
                done

            # debug prompt #
                # uncomment lines below #
                function DebugOutput {
                    echo -e "$0: ========== DEBUG PROMPT ==========\n"

                    for (( i=0 ; i<${#arr_devIndex_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIndex_sum[$i]}'\t= ${arr_devIndex_sum[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_devIOMMU_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIOMMU_sum[$i]}'\t= ${arr_devIOMMU_sum[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_devDriver_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devDriver_sum[$i]}'\t= ${arr_devDriver_sum[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_devHWID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devHWID_sum[$i]}'\t= ${arr_devHWID_sum[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_driver_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_driver_VFIO[$i]}'\t= ${arr_driver_VFIO[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO[$i]}'\t= ${arr_IOMMU_VFIO[$i]}"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host[$i]}'\t= ${arr_IOMMU_host[$i]}"; done && echo

                    echo -e "$0: '$""{#arr_devIndex_sum[@]}'\t= ${#arr_devIndex_sum[@]}"
                    echo -e "$0: '$""{#arr_devIOMMU_sum[@]}'\t= ${#arr_devIOMMU_sum[@]}"
                    echo -e "$0: '$""{#arr_devDriver_sum[@]}'\t= ${#arr_devDriver_sum[@]}"
                    echo -e "$0: '$""{#arr_devHWID_sum[@]}'\t= ${#arr_devHWID_sum[@]}"
                    echo -e "$0: '$""{#arr_driver_VFIO[@]}'\t= ${#arr_driver_VFIO[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_VFIO[@]}'\t= ${#arr_IOMMU_VFIO[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_host[@]}'\t= ${#arr_IOMMU_host[@]}"
                    echo -e "$0: '$""str_driver_VFIO_list'\t= $str_driver_VFIO_list"
                    echo -e "$0: '$""str_HWID_VFIO_list'\t= $str_HWID_VFIO_list"

                    echo -e "\n$0: ========== DEBUG PROMPT =========="
                    exit 0
                }

            # DebugOutput    # uncomment to debug here

        # parameters #
            bool_isVFIO=false
            bool_missingFiles=false

            # files #
                readonly str_dir1=`find .. -name files`
                if [[ -e $str_dir1 ]]; then
                    cd $str_dir1
                fi

                str_inFile1=`find . -name *etc_default_grub`
                str_inFile2=`find . -name *etc_modules`
                str_inFile3=`find . -name *etc_initramfs-tools_modules`
                str_inFile4=`find . -name *etc_modprobe.d_pci-blacklists.conf`
                str_inFile5=`find . -name *etc_modprobe.d_vfio.conf`

                # comment to debug here #
                str_outFile1="/etc/default/grub"
                str_outFile2="/etc/modules"
                str_outFile3="/etc/initramfs-tools/modules"
                str_outFile4="/etc/modprobe.d/pci-blacklists.conf"
                str_outFile5="/etc/modprobe.d/vfio.conf"

                # uncomment to debug here #
                # str_outFile1="grub.log"
                # str_outFile2="modules.log"
                # str_outFile3="initramfs_tools_modules.log"
                # str_outFile4="pci-blacklists.conf.log"
                # str_outFile5="vfio.conf.log"

                str_oldFile1=$str_outFile1".old"
                str_oldFile2=$str_outFile2".old"
                str_oldFile3=$str_outFile3".old"
                str_oldFile4=$str_outFile4".old"
                str_oldFile5=$str_outFile5".old"
                str_logFile1=$(pwd)"/grub.log"
                # none for file2-files5

            # clear files #     # NOTE: do NOT delete GRUB !!!
                if [[ -e $str_logFile1 ]]; then rm $str_logFile1; fi
                if [[ -e $str_logFile5 ]]; then rm $str_logFile5; fi

        # change parameters #
            if [[ ${str_driver_VFIO_list: -1} == "," ]]; then
                str_driver_VFIO_list=${str_driver_VFIO_list::-1}
            fi

            if [[ ${str_HWID_VFIO_list: -1} == "," ]]; then
                str_HWID_VFIO_list=${str_HWID_VFIO_list::-1}
            fi

        # VFIO soft dependencies #
            for str_driver in ${arr_driver_VFIO[@]}; do
                str_driverName_list_softdep+="\nsoftdep $str_driver pre: vfio-pci"
                str_driverName_list_softdep_drivers+="\nsoftdep $str_driver pre: vfio-pci\n$str_driver"
            done

        # /etc/default/grub #
            str_GRUB_CMDLINE+="$str_GRUB_CMDLINE_prefix modprobe.blacklist=$str_driver_VFIO_list vfio_pci.ids=$str_HWID_VFIO_list"

            str_output1="GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo "`lsb_release -i -s`"\`"
            str_output2="GRUB_CMDLINE_LINUX_DEFAULT=\"$str_GRUB_CMDLINE\""

            if [[ -e $str_inFile1 ]]; then
                if [[ -e $str_outFile1 ]]; then
                    mv $str_outFile1 $str_oldFile1      # create backup
                fi

                touch $str_outFile1

                # write to file #
                while read -r str_line1; do
                    if [[ $str_line1 == '#$str_output1'* ]]; then
                        str_line1=$str_output1
                    fi

                    if [[ $str_line1 == '#$str_output2'* ]]; then
                        str_line1=$str_output2
                    fi

                    echo -e $str_line1 >> $str_outFile1
                done < $str_inFile1
            else
                bool_missingFiles=true
            fi


        # /etc/modules #
            str_output1="vfio_pci ids=$str_HWID_VFIO_list"

            if [[ -e $str_inFile2 ]]; then
                if [[ -e $str_outFile2 ]]; then
                    mv $str_outFile2 $str_oldFile2      # create backup
                fi

                touch $str_outFile2

                # write to file #
                while read -r str_line1; do
                    if [[ $str_line1 == '#$str_output1'* ]]; then
                        str_line1=$str_output1
                    fi

                    echo -e $str_line1 >> $str_outFile2
                done < $str_inFile2
            else
                bool_missingFiles=true
            fi

        # /etc/initramfs-tools/modules #
            str_output1=$str_driverName_list_softdep_drivers
            str_output2="options vfio_pci ids=$str_HWID_VFIO_list\nvfio_pci ids=$str_HWID_VFIO_list\nvfio-pci"

            if [[ -e $str_inFile3 ]]; then
                if [[ -e $str_outFile3 ]]; then
                    mv $str_outFile3 $str_oldFile3      # create backup
                fi

                touch $str_outFile3

                # write to file #
                while read -r str_line1; do
                    if [[ $str_line1 == '#$str_output1'* ]]; then
                        str_line1=$str_output1
                    fi

                    if [[ $str_line1 == '#$str_output2'* ]]; then
                        str_line1=$str_output2
                    fi

                    echo -e $str_line1 >> $str_outFile3
                done < $str_inFile3
            else
                bool_missingFiles=true
            fi

        # /etc/modprobe.d/pci-blacklists.conf #
            str_output1=""

            for str_driver in ${arr_driver_VFIO[@]}; do
                str_output1+="blacklist $str_driver\n"
            done

            if [[ -e $str_inFile4 ]]; then
                if [[ -e $str_outFile4 ]]; then
                    mv $str_outFile4 $str_oldFile4      # create backup
                fi

                touch $str_outFile4

                # write to file #
                while read -r str_line1; do
                    if [[ $str_line1 == '#$str_output1'* ]]; then
                        str_line1=$str_output1
                    fi

                    echo -e $str_line1 >> $str_outFile4
                done < $str_inFile4
            else
                bool_missingFiles=true
            fi

        # /etc/modprobe.d/vfio.conf #
            str_output1="$str_driverName_list_softdep"
            str_output2="options vfio_pci ids=$str_HWID_VFIO_list"

            if [[ -e $str_inFile5 ]]; then
                if [[ -e $str_outFile5 ]]; then
                    mv $str_outFile5 $str_oldFile5      # create backup
                fi

                touch $str_outFile5

                # write to file #
                while read -r str_line1; do
                    if [[ $str_line1 == '#$str_output1'* ]]; then
                        str_line1=$str_output1
                    fi

                    if [[ $str_line1 == '#$str_output2'* ]]; then
                        str_line1=$str_output2
                    fi

                    if [[ $str_line1 == '#$str_output3'* ]]; then
                        str_line1=$str_output3
                    fi

                    echo -e $str_line1 >> $str_outFile5
                done < $str_inFile5
            else
                bool_missingFiles=true
            fi

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                bool_missingFiles=true
                echo -e "$0: File(s) missing:"

                if [[ -z $str_inFile1 ]]; then
                    echo -e "\t'$str_inFile1'"
                fi

                if [[ -z $str_inFile2 ]]; then
                    echo -e "\t'$str_inFile2'"
                fi

                if [[ -z $str_inFile3 ]]; then
                    echo -e "\t'$str_inFile3'"
                fi

                if [[ -z $str_inFile4 ]]; then
                    echo -e "\t'$str_inFile4'"
                fi

                if [[ -z $str_inFile5 ]]; then
                    echo -e "\t'$str_inFile5'"
                fi

                echo -e "$0: Executing Static setup... Failed."
                exit 0
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 ]]; then
                echo -e "$0: Executing Static setup... Cancelled. No IOMMU groups selected."
                exit 0
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Static setup... Complete."
            fi
    }

# prompt #
    declare -i int_count=0                  # reset counter

    while [[ $bool_isVFIO == false || -z $bool_isVFIO || $bool_missingFiles == false ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                  # default selection
        else
            echo -en "$0: Deploy Static VFIO setup? [Y/n]: "
            read -r str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
        fi

        case $str_input1 in
            "Y")
                echo
                StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_isVFIO
                echo
                sudo update-grub
                sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'\n\t'$str_outFile2'\n\t'$str_outFile3'\n\t'$str_outFile4'\n\t'$str_outFile5'"
                break;;
            "N")
                IFS=$SAVEIFS                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0;;
            *)
                echo -e "$0: Invalid input. ";;
        esac

        ((int_count++))                     # increment counter
    done

    # warn user to delete existing setup and reboot to continue #
    if [[ $bool_isVFIO == true && $bool_missingFiles == false ]]; then
        echo -en "$0: Existing VFIO setup detected. "

        if [[ -e `find .. -name *uninstall.bash*` ]]; then
            echo -e "To continue, execute `find .. -name *uninstall.bash*` and reboot system."
        else
            echo -e "To continue, uninstall setup and reboot system."
        fi
    fi

    # warn user of missing files #
    if [[ $bool_missingFiles == true ]]; then
        echo -e "$0: Setup is not complete. Clone or re-download 'portellam/deploy-VFIO-setup' to continue."
    fi
IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0