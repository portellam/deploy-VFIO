#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $0'\n\tor\n\t'su' and 'bash $0'.\n$0: Exiting."
        exit 0
    fi

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "install.d" ]]; then
        if [[ -e `find . -name install.d` ]]; then
            echo -e "$0: Script located the correct working directory."
            cd `find . -name install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    else
        echo -e "$0: Script is in the correct working directory."
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
    bool_dev_isExt=false
    bool_dev_isVFIO=false
    bool_dev_isVGA=false
    bool_missingFiles=false
    readonly int_lastIOMMU=`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | cut -d '/' -f5 | sort -hr | head -n1`
    str_IGPU_devName=""
    readonly str_logFile0=`find $(pwd) -name *hugepages*log*`

# GRUB and hugepages check #
    if [[ -z $str_logFile0 ]]; then
        echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_logFile0' and '$0'.\n"
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="
    else
        str_GRUB_CMDLINE_Hugepages=`cat $str_logFile0`
    fi

    str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages"

# catalog devices in each IOMMU group #
    function ParsePCI
    {

        # shell option #
            shopt -s nullglob

        # parameters #
            declare -a arr_IOMMU_sum=(`find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`)
            declare -a arr_devIndex_sum
            declare -a arr_devBusID_sum
            declare -a arr_devDriver_sum
            declare -a arr_devHWID_sum
            declare -a arr_devName_sum
            declare -i int_index=0

        # parse IOMMU groups #
            for str_line1 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                # parameters #
                    bool_dev_isExt=false
                    bool_dev_isVGA=false
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
                            arr_devIndex_sum+=($int_index)
                            arr_devBusID_sum+=($str_devBusID)
                            arr_devIOMMU_sum+=($int_thisIOMMU)
                            arr_devDriver_sum+=($str_devDriver)
                            arr_devHWID_sum+=($str_devHWID)
                            arr_devName_sum+=($str_devName)

                        # prompt #
                            echo
                            echo -e "\tBUS ID:\t\t$str_devBusID"
                            echo -e "\tVENDOR:\t\t$str_devVendor"
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

                            # set flag for external groups #
                            if [[ ${str_devBusID:1} != 0 || ${str_devBusID::2} -gt 0 ]]; then
                                bool_dev_isExt=true
                            else

                                # save name of IGPU dev name #
                                if [[ $str_devType == *'VGA'* || $str_devType == *'GRAPHICS'* ]]; then
                                    str_IGPU_devName=$str_devName
                                fi
                            fi

                        ((int_index++))
                    done

                # prompt #
                    if [[ $bool_dev_isExt == true ]]; then
                        echo
                        str_output1="Select IOMMU group '$int_IOMMU'? [Y/n]: "
                        ReadInput $str_output1

                        if [[ $bool_dev_isVGA == false ]]; then
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
                            case $str_input1 in
                                "Y")
                                    arr_IOMMU_VGA_VFIO+=("$int_IOMMU")
                                    echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                "N")
                                    arr_IOMMU_VGA_host+=("$int_IOMMU");;
                                *)
                                    echo -en "$0: Invalid input.";;
                            esac
                        fi
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

                            break;
                        fi
                done
            done

        # debug prompt #
            # uncomment lines below #
            function DebugOutput {
                echo -e "$0: ========== DEBUG PROMPT ==========\n"

                for (( i=0 ; i<${#arr_devIndex_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIndex_sum[$i]}'\t= ${arr_devIndex_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_devIOMMU_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIOMMU_sum[$i]}'\t= ${arr_devIOMMU_sum[$i]}"; done && echo
                for (( i=0 ; i<${#arr_devBusID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devBusID_sum[$i]}'\t= ${arr_devBusID_sum[$i]}"; done && echo
                # for (( i=0 ; i<${#arr_devDriver_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devDriver_sum[$i]}'\t= ${arr_devDriver_sum[$i]}"; done && echo
                # for (( i=0 ; i<${#arr_devHWID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devHWID_sum[$i]}'\t= ${arr_devHWID_sum[$i]}"; done && echo
                # for (( i=0 ; i<${#arr_devName_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devName_sum[$i]}'\t= ${arr_devName_sum[$i]}"; done && echo
                # for (( i=0 ; i<${#arr_driver_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_driver_VFIO[$i]}'\t= ${arr_driver_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO[$i]}'\t= ${arr_IOMMU_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host[$i]}'\t= ${arr_IOMMU_host[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VGA_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_VFIO[$i]}'\t= ${arr_IOMMU_VGA_VFIO[$i]}"; done && echo
                for (( i=0 ; i<${#arr_IOMMU_VGA_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_host[$i]}'\t= ${arr_IOMMU_VGA_host[$i]}"; done && echo


                echo -e "$0: '$""{#arr_devIndex_sum[@]}'\t= ${#arr_devIndex_sum[@]}"
                echo -e "$0: '$""{#arr_devIOMMU_sum[@]}'\t= ${#arr_devIOMMU_sum[@]}"
                echo -e "$0: '$""{#arr_devBusID_sum[@]}'\t= ${#arr_devBusID_sum[@]}"
                # echo -e "$0: '$""{#arr_devDriver_sum[@]}'\t= ${#arr_devDriver_sum[@]}"
                # echo -e "$0: '$""{#arr_devHWID_sum[@]}'\t= ${#arr_devHWID_sum[@]}"
                # echo -e "$0: '$""{#arr_devName_sum[@]}'\t= ${#arr_devName_sum[@]}"
                # echo -e "$0: '$""{#arr_driver_VFIO[@]}'\t= ${#arr_driver_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VFIO[@]}'\t= ${#arr_IOMMU_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_host[@]}'\t= ${#arr_IOMMU_host[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VGA_VFIO[@]}'= ${#arr_IOMMU_VGA_VFIO[@]}"
                echo -e "$0: '$""{#arr_IOMMU_VGA_host[@]}'= ${#arr_IOMMU_VGA_host[@]}"
                echo -e "$0: '$""str_driver_VFIO_list'\t= $str_driver_VFIO_list"
                echo -e "$0: '$""str_HWID_VFIO_list'\t= $str_HWID_VFIO_list"

                echo -e "\n$0: ========== DEBUG PROMPT =========="
                exit 0
            }

        # DebugOutput    # uncomment to debug here
    }

# Multi boot setup #
    function MultiBootSetup {

        # parse IOMMU groups #
            function ParseIOMMU
            {

                # parameters #
                    declare -a arr_driver_VGA_VFIO
                    str_driver_VGA_VFIO_list=""
                    str_HWID_VGA_VFIO_list=""
                    str_devFullName_VGA=""

                # shell option #
                    shopt -s nullglob

                # parse IOMMU #
                    for str_line1 in $(find /sys/kernel/iommu_groups/$int_IOMMU -maxdepth 0 -type d | sort -V); do

                        # parameters #
                            bool_dev_isExt=false
                            bool_dev_isVGA=false
                            declare -i int_IOMMU=`echo $str_line1 | cut -d '/' -f5`

                        # parse devices #
                            for str_line2 in $str_line1/devices/*; do

                                # parameters #
                                    str_devDriver=`lspci -nnks ${str_line2##*/} | grep 'driver' | cut -d ':' -f2 | cut -d ' ' -f2`
                                    str_devHWID=`lspci -ns ${str_line2##*/} | cut -d ' ' -f3`
                                    str_devName=`lspci -ms ${str_line2##*/} | cut -d '"' -f6`
                                    str_devType=`lspci -ms ${str_line2##*/} | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`
                                    str_devVendor=`lspci -ms ${str_line2##*/} | cut -d '"' -f4`

                                # new parameters #
                                    str_HWID_VFIO_list+="$str_thisDevHWID,"

                                    if [[ $str_thisDevDriver != "" ]]; then
                                        arr_driver_VGA_VFIO+=("$str_thisDevDriver")
                                        str_driver_VGA_VFIO_list+="$str_thisDevDriver,"
                                    fi

                                    if [[ $str_devType == *'VGA'* || $str_devType == *'GRAPHICS'* ]]; then
                                        str_devFullName_VGA="$str_devVendor $str_devName"
                                    fi
                            done
                    done

            }

        echo -e "$0: Executing Multi-boot setup..."
        ParsePCI                                        # call function

        # function #
            function WriteToFile {

                if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then

                    # write to tempfile #
                    echo -e \n\n $str_line1 >> $str_outFile1
                    echo -e \n\n $str_line1 >> $str_logFile1
                    while read -r str_line1; do
                        case $str_line1 in
                            *'#$str_output1'*)
                                str_line1=$str_output1
                                echo -e $str_output1_log >> $str_logFile1;;
                            *'#$str_output2'*)
                                str_line1=$str_output2;;
                            *'#$str_output3'*)
                                str_line1=$str_output3;;
                            *'#$str_output4'*)
                                str_line1=$str_output4;;
                            *'#$str_output5'*)
                                str_line1=$str_output5
                                echo -e $str_output5_log >> $str_logFile1;;
                            *'#$str_output6'*)
                                str_line1=$str_output6
                                echo -e $str_output6_log >> $str_logFile1;;
                            *'#$str_output7'*)
                                str_line1=$str_output7
                                echo -e $str_output7_log >> $str_logFile1;;
                            *)
                                break;;
                        esac

                        echo -e $str_line1 >> $str_outFile1
                        echo -e $str_line1 >> $str_logFile1
                    done < $str_inFile1b        # read from template
                else
                    bool_missingFiles=true
                fi
            }

        # parameters #
            readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
            declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n2`)     # all kernels       # NOTE: create boot menu entries for first two kernels.                        any more is overkill!
            #str_rootKernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`                   # latest kernel
            #readonly str_rootKernel=${str_rootKernel: 1}
            readonly str_rootDisk=`df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1`
            readonly str_rootUUID=`blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2`
            str_rootFSTYPE=`blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2`

            if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then
                readonly str_rootFSTYPE="ext2"
            fi

            # files #
                readonly str_dir1=`find .. -name files`
                if [[ -e $str_dir1 ]]; then
                    cd $str_dir1
                fi

                readonly str_inFile1=`find . -name *etc_grub.d_proxifiedScripts_custom`
                readonly str_inFile1b=`find . -name *custom_grub_template`
                # readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"

                # DEBUG #
                readonly str_outFile1="custom.log"
                readonly str_oldFile1=$str_outFile1".old"
                readonly str_logFile1=$(pwd)"/custom-grub.log"

            echo -e "$0: '$""str_IGPU_devName'\t\t= $str_IGPU_devName"
            echo -e "$0: '$""str_rootDistro'\t\t= $str_rootDistro"
            echo -e "$0: '$""str_rootKernel'\t\t= $str_rootKernel"
            echo -e "$0: '$""{#arr_rootKernel[@]}'\t\t= ${#arr_rootKernel[@]}"
            echo -e "$0: '$""str_rootDisk'\t\t= $str_rootDisk"
            echo -e "$0: '$""str_rootUUID'\t\t= $str_rootUUID"
            echo -e "$0: '$""str_rootFSTYPE'\t\t= $str_rootFSTYPE"
            echo -e "$0: '$""str_inFile1'\t\t= $str_inFile1"
            echo -e "$0: '$""str_inFile1b'\t\t= $str_inFile1b"
            echo -e "$0: '$""str_outFile1'\t\t= $str_outFile1"
            echo -e "$0: '$""str_oldFile1'\t\t= $str_oldFile1"
            echo -e "$0: '$""str_logFile1'\t\t= $str_logFile1"
            echo -e "$0: '$""{#arr_IOMMU_VGA_VFIO[@]}'\t\t= ${#arr_IOMMU_VGA_VFIO[@]}"
            echo

            # create logfile #
            if [[ -z $str_logFile1 ]]; then
                touch $str_logFile1
            fi

            # create backup #
            if [[ -e $str_outFile1 ]]; then
                mv $str_outFile1 $str_oldFile1
            fi

            # restore backup #
            if [[ -e $str_inFile1 ]]; then
                cp $str_inFile1 $str_outFile1
            fi

        # generate output for system files #
            for int_IOMMU in ${arr_IOMMU_VGA_VFIO[@]}; do

                # reset parameters #
                    declare -a arr_GRUB_title
                    declare -a arr_IOMMU_VFIO_temp
                    str_devFullName_VGA="N/A"
                    str_driver_VFIO_thisList=""
                    str_driver_VFIO_thisList=""
                    str_GRUB_CMDLINE=""

                ParseIOMMU                          # call function

                # update GRUB title with kernel(s) #
                    if [[ $str_IGPU_devName == "" ]]; then
                        #str_GRUB_title="`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO, w/o IOMMU '$int_IOMMU', w/ boot VGA '$str_IGPU_devName')"

                        for str_rootKernel in ${arr_rootKernel[@]}; do
                            arr_GRUB_title+=("`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO, w/o IOMMU '$int_IOMMU', w/ boot VGA '$str_IGPU_devName')")
                        done
                    else
                        #str_GRUB_title="`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO, w/o IOMMU '$int_IOMMU', w/ boot VGA '$str_devFullName_VGA')"

                        for str_rootKernel in ${arr_rootKernel[@]}; do
                            arr_GRUB_title+=("`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO, w/o IOMMU '$int_IOMMU', w/ boot VGA '$str_devFullName_VGA')")
                        done
                    fi

                # update parameters #
                    str_driver_VFIO_thisList=${str_driver_VFIO_thisList}${str_driver_VFIO_list}
                    str_HWID_VGA_VFIO_list=${str_HWID_VFIO_thisList}${str_HWID_VFIO_list}

                    # remove last separator #
                        if [[ ${str_driver_VFIO_thisList: -1} == "," ]]; then
                            str_driver_VFIO_thisList=${str_driver_VFIO_thisList::-1}
                        fi

                        if [[ ${str_HWID_VGA_VFIO_list: -1} == "," ]]; then
                            str_HWID_VGA_VFIO_list=${str_HWID_VGA_VFIO_list::-1}
                        fi

                # Write to file #
                    # new parameters #

                        str_GRUB_CMDLINE+="$str_GRUB_CMDLINE_prefix modprobe.blacklist=$str_driver_VFIO_thisList vfio_pci.ids=$str_HWID_VFIO_thisList"

                    ## /etc/grub.d/proxifiedScripts/custom ##
                        if [[ ${#arr_GRUB_title[@]} -gt 1 ]]; then

                            # parse every kernel/new GRUB title #
                            for str_GRUB_title in ${arr_GRUB_title[@]}; do
                                # new parameters #
                                    str_output1="menuentry \"$str_GRUB_title\"{"
                                    str_output2="    insmod $str_rootFSTYPE"
                                    str_output3="    set root='/dev/disk/by-uuid/$str_rootUUID'"
                                    str_output4="        search --no-floppy --fs-uuid --set=root $str_rootUUID"
                                    str_output5="    echo    'Loading Linux $str_rootKernel ...'"
                                    str_output6="    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                                    str_output7="    initrd  /boot/initrd.img-$str_rootKernel"

                                    # echo -e "$0: '$""str_output1'\t\t= $str_output1"
                                    # echo -e "$0: '$""str_output2'\t\t= $str_output2"
                                    # echo -e "$0: '$""str_output3'\t\t= $str_output3"
                                    # echo -e "$0: '$""str_output4'\t\t= $str_output4"
                                    # echo -e "$0: '$""str_output5'\t\t= $str_output5"
                                    # echo -e "$0: '$""str_output6'\t\t= $str_output6"
                                    # echo -e "$0: '$""str_output7'\t\t= $str_output7"
                                    # echo

                                # WriteToFile     # call function

                                if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then
                                    # write to tempfile #
                                    echo -e \n\n $str_line1 >> $str_outFile1
                                    echo -e \n\n $str_line1 >> $str_logFile1
                                    while read -r str_line1; do
                                        if [[ $str_line1 == '#$str_output1'* ]]; then
                                            str_line1=$str_output1
                                            # echo -e $str_output1_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output2'* ]]; then
                                            str_line1=$str_output2
                                        fi

                                        if [[ $str_line1 == '#$str_output3'* ]]; then
                                            str_line1=$str_output3
                                        fi

                                        if [[ $str_line1 == '#$str_output4'* ]]; then
                                            str_line1=$str_output4
                                        fi

                                        if [[ $str_line1 == '#$str_output5'* ]]; then
                                            str_line1=$str_output5
                                            # echo -e $str_output5_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output6'* ]]; then
                                            str_line1=$str_output6
                                            # echo -e $str_output6_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output7'* ]]; then
                                            str_line1=$str_output7
                                            # echo -e $str_output7_log >> $str_logFile1
                                        fi

                                        echo -e $str_line1 >> $str_outFile1
                                        echo -e $str_line1 >> $str_logFile1
                                    done < $str_inFile1b        # read from template
                                else
                                    bool_missingFiles=true
                                fi
                            done
                        else
                            # new parameters #
                                str_output1="menuentry \"$str_GRUB_title\"{"
                                str_output2="    insmod $str_rootFSTYPE"
                                str_output3="    set root='/dev/disk/by-uuid/$str_rootUUID'"
                                str_output4="        search --no-floppy --fs-uuid --set=root $str_rootUUID"
                                str_output5="    echo    'Loading Linux $str_rootKernel ...'"
                                str_output6="    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                                str_output7="    initrd  /boot/initrd.img-$str_rootKernel"

                                # echo -e "$0: '$""str_output1'\t\t= $str_output1"
                                # echo -e "$0: '$""str_output2'\t\t= $str_output2"
                                # echo -e "$0: '$""str_output3'\t\t= $str_output3"
                                # echo -e "$0: '$""str_output4'\t\t= $str_output4"
                                # echo -e "$0: '$""str_output5'\t\t= $str_output5"
                                # echo -e "$0: '$""str_output6'\t\t= $str_output6"
                                # echo -e "$0: '$""str_output7'\t\t= $str_output7"

                            # WriteToFile         # call function

                            if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then
                                    # write to tempfile #
                                    echo -e \n\n $str_line1 >> $str_outFile1
                                    echo -e \n\n $str_line1 >> $str_logFile1
                                    while read -r str_line1; do
                                        if [[ $str_line1 == '#$str_output1'* ]]; then
                                            str_line1=$str_output1
                                            # echo -e $str_output1_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output2'* ]]; then
                                            str_line1=$str_output2
                                        fi

                                        if [[ $str_line1 == '#$str_output3'* ]]; then
                                            str_line1=$str_output3
                                        fi

                                        if [[ $str_line1 == '#$str_output4'* ]]; then
                                            str_line1=$str_output4
                                        fi

                                        if [[ $str_line1 == '#$str_output5'* ]]; then
                                            str_line1=$str_output5
                                            # echo -e $str_output5_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output6'* ]]; then
                                            str_line1=$str_output6
                                            # echo -e $str_output6_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == '#$str_output7'* ]]; then
                                            str_line1=$str_output7
                                            # echo -e $str_output7_log >> $str_logFile1
                                        fi

                                        echo -e $str_line1 >> $str_outFile1
                                        echo -e $str_line1 >> $str_logFile1
                                    done < $str_inFile1b        # read from template
                                else
                                    bool_missingFiles=true
                            fi
                        fi
            done

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                echo -e "$0: File(s) missing:"

                if [[ -z $str_inFile1 ]]; then
                    echo -e "\t'$str_inFile1'"
                fi

                if [[ -z $str_inFile1b ]]; then
                    echo -e "\t'$str_inFile1b'"
                fi

                echo -e "$0: Executing Multi-boot setup... Failed."
                exit 0
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -ge 1 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups (with VGA devices) selected."
                exit 0
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -eq 0 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups selected."
                exit 0
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Multi-boot setup... Complete."
            fi
    }

# Static setup #
    function StaticSetup {

        echo -e "$0: Executing Static setup..."
        declare -a arr_devBusID_sum
        ParsePCI                                        # call function

        # parameters #
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
                # str_outFile1="/etc/default/grub"
                # str_outFile2="/etc/modules"
                # str_outFile3="/etc/initramfs-tools/modules"
                # str_outFile4="/etc/modprobe.d/pci-blacklists.conf"
                # str_outFile5="/etc/modprobe.d/vfio.conf"
                str_outFile1="grub.log"
                str_outFile2="modules.log"
                str_outFile3="initramfs_tools_modules.log"
                str_outFile4="pci-blacklists.conf.log"
                str_outFile5="vfio.conf.log"
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

        # generate output for system files #
            # parameters #
                declare -a arr_driver_VGA_VFIO

            # shell option #
                shopt -s nullglob

            echo -e '${#arr_devBusID_sum[@]} == '${#arr_devBusID_sum[@]}

            # parse IOMMU #
                for int_IOMMU in ${arr_IOMMU_VGA_VFIO[@]}; do
                    for str_line1 in `find /sys/kernel/iommu_groups/$int_IOMMU/devices/*`; do

                        # parameters #
                            str_devBusID=`echo ${str_line1##*/}`
                            echo '$0: $str_devBusID == '$str_devBusID

                            for (( int_i=0 ; int_i<${#arr_devBusID_sum[$int_i]} ; int_i++ )); do
                                echo '$0: ${arr_devBusID_sum[$int_i]} == '${arr_devBusID_sum[$int_i]}
                                echo '$0: $str_devDriver == '$str_devDriver
                                echo '$0: $str_devHWID == '$str_devHWID

                                if [[ ${arr_devBusID_sum[$int_i]} == *$str_devBusID* ]]; then
                                    str_devDriver=${arr_devDriver_sum[$int_i]}
                                    str_devHWID=${arr_devHWID_sum[$int_i]}
                                    break
                                fi
                            done

                        # new parameters #
                            str_HWID_VFIO_list+="$str_devHWID,"

                            if [[ $str_thisDevDriver != "" ]]; then
                                arr_driver_VGA_VFIO+=($str_devDriver)
                                str_driver_VFIO_list+="$str_devDriver,"
                            fi
                    done
                done

        # change parameters #
            if [[ ${str_driver_VFIO_list: -1} == "," ]]; then
                str_driver_VFIO_list=${str_driver_VFIO_list::-1}
            fi

            if [[ ${str_HWID_VFIO_list: -1} == "," ]]; then
                str_HWID_VFIO_list=${str_HWID_VFIO_list::-1}
            fi

        # VFIO soft dependencies #
            for str_driver in ${arr_driver_VGA_VFIO[@]}; do
                str_driverName_list_softdep+="\nsoftdep $str_driver pre: vfio-pci"
                str_driverName_list_softdep_drivers+="\nsoftdep $str_driver pre: vfio-pci\n$str_driver"
            done

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

            for str_driver in ${arr_driver_VGA_VFIO[@]}; do
                str_output1+="blacklist $str_driver\n"
            done

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
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -eq 0 ]]; then
                echo -e "$0: Executing Static setup... Cancelled. No IOMMU groups selected."
                exit 0
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Static setup... Complete."
            fi
    }

# prompt #
    declare -i int_count=0                  # reset counter
    echo -en "$0: Deploy VFIO setup: Multi-Boot or Static?\n\t'Multi-Boot' is more flexible; adds multiple GRUB boot menu entries (each with one different, omitted IOMMU group).\n\t'Static', for unchanging setups.\n\t'Multi-Boot' is the recommended choice.\n"

    while [[ $bool_dev_isVFIO == false || -z $bool_dev_isVFIO || $bool_missingFiles == false ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                  # default selection
        else
            echo -en "\n$0: Deploy VFIO setup? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
            read -r str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
        fi

        case $str_input1 in
            "M")
                echo
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $bool_dev_isVFIO
                echo
                sudo update-grub
                sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'"
                break;;
            "S")
                echo
                StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_dev_isVFIO
                echo
                sudo update-grub
                sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'\n\t'$str_outFile2'\n\t'$str_outFile3'\n\t'$str_outFile4'\n\t'$str_outFile5'"
                break;;
            "N")
                echo
                echo -e "$0: Skipping."
                IFS=$SAVEIFS                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0;;
            *)
                echo -e "$0: Invalid input.";;
        esac

        ((int_count++))                     # increment counter
    done

    # warn user to delete existing setup and reboot to continue #
    if [[ $bool_dev_isVFIO == true && $bool_missingFiles == false ]]; then
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