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

# prompt #
    str_output1="\n$0: Please wait. Calculating..."
    echo -e $str_output1

# parameters #
    readonly arr_devices1=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)
    readonly arr_devices2=(`lspci -m`)
    readonly arr_devices3=(`lspci -nk | grep -Eiv 'devicename|subsystem|modules'`)
    readonly arr_IOMMU_sum=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | cut -d '/' -f5 | sort -h`)
    declare -a arr_busID_sum
    declare -a arr_deviceName_sum
    declare -a arr_deviceType_sum
    declare -a arr_driver_sum
    declare -a arr_HWID_sum
    declare -a arr_vendorName_sum
    declare -a arr_IOMMU_host
    declare -a arr_IOMMU_VFIO
    declare -a arr_IOMMU_VGA_host
    declare -a arr_IOMMU_VGA_VFIO
    declare -a arr_driver_VFIO
    declare -a arr_HWID_VFIO
    bool_existingSetup=false
    bool_hasVGA=false
    bool_hasExternalPCI=false
    bool_missingFiles=false
    readonly int_lastIOMMU=${arr_IOMMU_sum[-1]}
    str_bootVGA_deviceName=""
    str_driver_VFIO_list=""
    str_HWID_VFIO_list=""
    str_GRUB_CMDLINE=""
    readonly str_logFile0=`find $(pwd) -name *hugepages*log*`

# sort Bus ID by IOMMU group ID #
    for (( int_i=0 ; int_i < ${#arr_IOMMU_sum[@]} ; int_i++ )); do
        for str_element1 in ${arr_devices1[@]}; do
            str_thisIOMMU=`echo $str_element1 | cut -d '/' -f5`
            str_thisBusID=`echo $str_element1 | cut -d '/' -f7 | cut -d ' ' -f1`
            str_thisBusID=${str_thisBusID:5}

            # match IOMMU group ID, save Bus ID #
            if [[ $str_thisIOMMU == $int_i ]]; then
                arr_busID_sum+=($str_thisBusID)
            fi
        done
    done

# sort devices' names and types by Bus ID and IOMMU group ID #
    for str_BusID in ${arr_busID_sum[@]}; do
        for str_element1 in ${arr_devices1[@]}; do
            str_thisBusID=`echo $str_element1 | cut -d '/' -f7 | cut -d ' ' -f1`
            str_thisBusID=${str_thisBusID:5}

            # match Bus ID #
            if [[ $str_BusID == $str_thisBusID ]]; then
                arr_deviceName_sum+=(`echo $str_element1 | cut -d '"' -f6`)
                arr_deviceType_sum+=(`echo $str_element1 | cut -d '"' -f2`)
                arr_vendorName_sum+=(`echo $str_element1 | cut -d '"' -f4`)
                break
            fi
        done
    done

# sort devices' drivers and HWIDs by Bus ID and IOMMU group ID #
    for str_BusID in ${arr_busID_sum[@]}; do
        bool_readNextLine=false

        for str_element1 in ${arr_devices3[@]}; do

            # false match Bus ID #
            if [[ $bool_readNextLine == false && $str_element1 != *`echo $str_element1 | cut -d ' ' -f1`* && $str_element1 != *"driver"* ]]; then
                break
            fi

            # match driver, add to list #
            if [[ $bool_readNextLine == true && $str_element1 == *"driver"* ]]; then

                # vfio driver found, exit #
                if [[ $str_element1 == 'vfio-pci' ]]; then
                    bool_existingSetup=true
                fi

                arr_driver_sum+=(`echo $str_element1 | grep "driver" | cut -d ' ' -f5`)
                break
            fi

            # false match driver, add null to list #
            if [[ $bool_readNextLine == true && $str_element1 != *"driver"* ]]; then
                arr_driver_sum+=("NULL")
                break
            fi

            # match Bus ID, update boolean #
            if [[ $bool_readNextLine == false && $str_BusID == *`echo $str_element1 | cut -d ' ' -f1`* ]]; then
                arr_HWID_sum+=(`echo $str_element1 | cut -d ' ' -f3`)
                bool_readNextLine=true
            fi
        done
    done

# # add VFIO groups' w/o VGA (drivers and HWIDs) to lists #
#     # MultiBoot, parse each VGA VFIO group for individual boot entries
#     # Static, add all groups to new list
#     for str_IOMMU in ${arr_IOMMU_VFIO[@]}; do
#         for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do

#             # match IOMMU group ID #
#             if [[ $str_IOMMU == ${arr_IOMMU_sum[$int_i]} ]]; then
#                 arr_driver_VFIO+=(${arr_driver_sum[$int_i]})
#                 arr_HWID_VFIO+=(${arr_HWID_sum[$int_i]})
#                 str_driver_VFIO_list+=(${arr_driver_sum[$int_i]})","
#                 str_HWID_VFIO_list+=(${arr_HWID_sum[$int_i]})","
#             fi
#         done
#     done

# # change parameters #
    # remove last separator #
    if [[ ${str_driver_VFIO_list: -1} == "," ]]; then
        str_driver_VFIO_list=${str_driver_VFIO_list::-1}
    fi

    if [[ ${str_HWID_VFIO_list: -1} == "," ]]; then
        str_HWID_VFIO_list=${str_HWID_VFIO_list::-1}
    fi

    readonly arr_busID_sum
    readonly arr_deviceName_sum
    readonly arr_deviceType_sum
    readonly arr_deviceName_sum
    readonly arr_HWID_sum
    readonly arr_vendorName_sum
    readonly arr_IOMMU_host
    readonly arr_IOMMU_VFIO
    readonly arr_IOMMU_VGA_host
    readonly arr_IOMMU_VGA_VFIO
    readonly arr_driver_VFIO
    readonly arr_HWID_VFIO
    readonly str_bootVGA_deviceName
    readonly str_driver_VFIO_list
    readonly str_HWID_VFIO_list

# user input prompt #
    str_input1=""

    # precede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {
        echo -en "$0: "

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

# prompt #
    str_output1="\n$0: PLEASE READ:
    \n\t\tSome PCI devices present may share IOMMU groups.
    \n\t\tDevices that share IOMMU groups must be passed-through as all or none.
    \n\t\tEvaluate order of PCI slots (devices) to for optimal IOMMU groups.
    \n\n$0: WARNING:
    \n\t\t'ACS-Override patch' exists to divide IOMMU groups, but said patch creates an attack vector (memory read/write across PCI devices) and is not recommended (for security reasons).\n"

    echo -e $str_output1

# Parse and Prompt PCI devices #
    function ParsePCI {

        # passthrough IOMMU group ID by user descretion #
            declare int_IOMMU=0

            while [[ $int_IOMMU -le ${arr_IOMMU_sum[-1]} ]]; do

                # match Bus ID and device type #
                for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do
                    str_IOMMU=${arr_IOMMU_sum[$int_i]}
                    str_thisBusID=`echo ${arr_busID_sum[$int_i]} | cut -d ':' -f2`
                    declare -i int_thisBusID=$((str_thisBusID))
                    str_thisDeviceType=`echo $str_element2 | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`

                    # save IOMMU group in separate list #
                    if [[ $str_IOMMU == $int_IOMMU && $str_thisDeviceType == *"VGA"* && $str_thisDeviceType == *"GRAPHICS"* ]]; then
                        bool_hasVGA=true
                    fi

                    # show only IOMMU groups with external PCI #
                    if [[ $str_IOMMU == $int_IOMMU && `echo ${#arr_busID_sum[$int_i]} | cut -d ':' -f2` -ge 1 ]]; then
                        bool_hasExternalPCI=true
                    fi

                    # save first found internal VGA device #
                    if [[ $str_IOMMU == $int_IOMMU && $bool_hasVGA == true && $bool_hasExternalPCI == false ]]; then
                        str_bootVGA_deviceName=${arr_deviceName_sum[$int_i]}
                    fi

                    echo -e '$str_IOMMU == '$str_IOMMU
                    echo -e '${arr_busID_sum['$int_i']} == '${arr_busID_sum[$int_i]}
                    echo -e '$str_thisBusID == '$str_thisBusID
                    echo -e '$int_thisBusID == '$int_thisBusID
                    echo -e '$str_thisDeviceType == '$str_thisDeviceType
                    echo -e '$bool_hasVGA == '$bool_hasVGA
                    echo -e '$bool_hasExternalPCI == '$bool_hasExternalPCI
                    echo -e '$str_bootVGA_deviceName == '$str_bootVGA_deviceName

                done

                # prompt #
                echo

                if [[ $bool_hasExternalPCI == true ]]; then
                    echo -e "\tIOMMU:\t\t$int_IOMMU"

                    # new prompt #
                    for (( int_i=0 ; int_i<${#arr_thisIOMMU[@]} ; int_i++ )); do
                        echo -e "\tVENDOR:\t\t${arr_vendorName_sum[$int_i]}"
                        echo -e "\tNAME:\t\t${arr_deviceName_sum[$int_i]}"
                        echo -e "\tTYPE  :\t\t${arr_deviceType_sum[$int_i]}"
                        echo -e "\tBUS ID:\t\t${arr_busID_sum[$int_i]}"
                        echo -e "\tHW ID :\t\t${arr_HWID_sum[$int_i]}"
                        echo -e "\tDRIVER:\t\t${arr_driver_sum[$int_i]}"
                        echo
                    done

                    str_output1="Select IOMMU group ID '$int_IOMMU'? [Y/n]: "
                    ReadInput $str_output1

                    if [[ $bool_hasVGA == false ]]; then
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIO+=$int_IOMMU
                                echo "Selected IOMMU group ID '$int_IOMMU'."
                                ;;
                            "N")
                                arr_IOMMU_host+=$int_IOMMU
                                ;;
                            *)
                                echo -en "$0: Invalid input."
                                ;;
                        esac
                    else
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VGA_VFIO+=$int_IOMMU
                                echo "Selected IOMMU group ID '$int_IOMMU'."
                                ;;
                            "N")
                                arr_IOMMU_VGA_host+=$int_IOMMU
                                ;;
                            *)
                                echo -en "$0: Invalid input."
                                ;;
                        esac
                    fi
                else
                    echo -e "IOMMU group ID '$int_IOMMU' has no external PCI devices. Skipping."
                fi

                bool_hasVGA=false
                bool_hasExternalPCI=false
                ((int_IOMMU++))
            done
    }

# GRUB and hugepages check #
    if [[ -z $str_logFile0 ]]; then
        echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_logFile0' and '$0'.\n"
        readonly str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="
    else
        readonly str_GRUB_CMDLINE_Hugepages=`cat $str_logFile0`
    fi

    readonly str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages"

# Multi boot setup #
    function MultiBootSetup {

        echo -e "$0: Executing Multi-boot setup..."
        ParsePCI                                        # call function

        # parameters #
            bool_hasInternalVGA=false
            readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
            declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n2`)     # all kernels       # NOTE: create boot menu entries for first two kernels.
                                                                                                        #                           any more is overkill!
            str_rootKernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`                   # latest kernel
            readonly str_rootKernel=${str_rootKernel: 1}
            readonly str_rootDisk=`df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1`
            readonly str_rootUUID=`blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2`
            readonly str_rootFSTYPE=`blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2`

            if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then
                readonly str_rootFSTYPE="ext2"
            fi

            # files #
                readonly str_inFile1=`find . -name *etc_grub.d_proxifiedScripts_custom`
                readonly str_inFile1b=`find . -name *custom_grub_template`
                #readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"                # DEBUG
                readonly str_outFile1="custom.log"                                          # DEBUG
                readonly str_oldFile1=$str_outFile1".old"
                readonly str_logFile1=$(pwd)"/custom-grub.log"

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

        # parse list of VGA IOMMU groups, output to file #
            for str_IOMMU in ${arr_IOMMU_VGA_VFIO[@]}; do

                # reset parameters #
                    declare -a arr_GRUB_title
                    str_driver_VFIO_thisList=""
                    str_HWID_VFIO_thisList=""
                    str_GRUB_CMDLINE=""

                # find device name of first found VGA device #
                    for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do
                        str_thisIOMMU=${arr_IOMMU_sum[$int_i]}arr_deviceName_sum
                        str_thisDeviceType=`echo ${arr_deviceType_sum[$int_i]} | tr '[:lower:]' '[:upper:]'`
                        str_thisDeviceName=${arr_deviceName_sum[$int_i]}
                        str_thisDriver=${arr_driver_sum[$int_i]}
                        str_thisHWID=${arr_HWID_sum[$int_i]}

                        # match IOMMU ID #
                        if [[ $str_thisIOMMU == $str_IOMMU ]]; then

                            # false match device type, reset #
                            if [[ $bool_hasInternalVGA == false && $str_thisDeviceType != *"VGA"* && $str_thisDeviceType != *"GRAPHICS"* ]]; then
                                str_thisDeviceName="N/A"
                            fi
                        else
                            str_driver_VFIO_thisList+=$str_thisDriver","
                            str_HWID_VFIO_thisList+=$str_thisHWID","
                        fi
                    done

                # change parameters #
                    str_driver_VFIO_thisList+=$str_driver_VFIO_list
                    str_HWID_VFIO_thisList+=$str_HWID_VFIO_list

                    # remove last separator #
                        if [[ ${str_driver_VFIO_thisList: -1} == "," ]]; then
                            str_driver_VFIO_thisList=${str_driver_VFIO_thisList::-1}
                        fi

                        if [[ ${str_HWID_VFIO_thisList: -1} == "," ]]; then
                            str_HWID_VFIO_thisList=${str_HWID_VFIO_thisList::-1}
                        fi

                # update GRUB title with kernel(s) #
                    if [[ $str_bootVGA_deviceName == "" ]]; then
                        str_GRUB_title="`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO IOMMU group '$str_IOMMU', boot VGA '$str_bootVGA_deviceName')"

                        for $str_rootKernel in ${arr_rootKernel[@]}; do
                            arr_GRUB_title+=("`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO IOMMU group '$str_IOMMU', boot VGA '$str_bootVGA_deviceName')")
                        done
                    else
                        str_GRUB_title="`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO IOMMU group '$str_IOMMU', boot VGA '$str_thisDeviceName')"

                        for $str_rootKernel in ${arr_rootKernel[@]}; do
                            arr_GRUB_title+=("`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VFIO IOMMU group '$str_IOMMU', boot VGA '$str_thisDeviceName')")
                        done
                    fi

                # match valid device name #
                    if [[ $str_thisVGA_DeviceName != "" ]]; then

                    # Write to file #
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

                    # new parameters #
                        str_GRUB_CMDLINE+="$str_GRUB_CMDLINE_prefix modprobe.blacklist=$str_driver_VFIO_thisList vfio_pci.ids=$str_HWID_VFIO_thisList"

                    ## /etc/grub.d/proxifiedScripts/custom ##
                        if [[ ${#arr_GRUB_title[@]} -gt 1 ]]; then
                            for str_GRUB_title in ${arr_GRUB_title[@]}; do
                                # new parameters #
                                    str_output1="menuentry \"$str_GRUB_title\"{"
                                    str_output2="    insmod $str_rootFSTYPE"
                                    str_output3="    set root='/dev/disk/by-uuid/$str_rootUUID'"
                                    str_output4="        search --no-floppy --fs-uuid --set=root $str_rootUUID"
                                    str_output5="    echo    'Loading Linux $str_rootKernel ...'"
                                    str_output6="    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                                    str_output7="    initrd  /boot/initrd.img-$str_rootKernel"

                                WriteToFile     # call function
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

                            WriteToFile         # call function
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
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -ge 1 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups (with VGA devices) selected."
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -eq 0 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups selected."
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Multi-boot setup... Complete."
            fi
    }

# Static setup #
    function StaticSetup {

        echo -e "$0: Executing Static setup..."
        ParsePCI                                        #call function

        # parameters #
            declare -a arr_driverName_list

            # files #
                str_inFile1=`find . -name *etc_default_grub`
                str_inFile2=`find . -name *etc_modules`
                str_inFile3=`find . -name *etc_initramfs-tools_modules`
                str_inFile4=`find . -name *etc_modprobe.d_pci-blacklists.conf`
                str_inFile5=`find . -name *etc_modprobe.d_vfio.conf`
                #str_outFile1="/etc/default/grub"
                #str_outFile2="/etc/modules"
                #str_outFile3="/etc/initramfs-tools/modules"
                #str_outFile4="/etc/modprobe.d/pci-blacklists.conf"
                #str_outFile5="/etc/modprobe.d/vfio.conf"
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
                # none for file2-file5

            # clear files #     # NOTE: do NOT delete GRUB !!!
                if [[ -e $str_logFile1 ]]; then rm $str_logFile1; fi
                if [[ -e $str_logFile5 ]]; then rm $str_logFile5; fi

        # VFIO soft dependencies #
            for str_thisDriverName in ${arr_driverName_list[@]}; do
                str_driverName_list_softdep+="\nsoftdep $str_thisDriverName pre: vfio-pci"
                str_driverName_list_softdep_drivers+="\nsoftdep $str_thisDriverName pre: vfio-pci\n$str_thisDriverName"
            done

        # /etc/default/grub #
            str_GRUB_CMDLINE+="$str_GRUB_CMDLINE_prefix modprobe.blacklist=$str_driverName_newList vfio_pci.ids=$str_HWID_list"

            str_output1="GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo "`lsb_release -i -s`"\`"
            str_output2="GRUB_CMDLINE_LINUX_DEFAULT=\"$str_GRUB_CMDLINE\""

            if [[ -e $str_inFile1 ]]; then
                if [[ -e $str_outFile1 ]]; then
                    mv $str_outFile1 $str_oldFile1      # create backup
                fi

                touch $str_outFile1

                # write to file #
                while read -r str_line1; do
                    case $str_line1 in
                        *'#$str_output1'*)
                            str_line1=$str_output1;;
                        *'#$str_output2'*)
                            str_line1=$str_output2;;
                        *)
                            break;;
                    esac

                    echo -e $str_line1 >> $str_outFile1
                done < $str_inFile1
            else
                bool_missingFiles=true
            fi


        # /etc/modules #
            str_output1="vfio_pci ids=$str_HWID_list"

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
            str_output2="options vfio_pci ids=$str_HWID_list\nvfio_pci ids=$str_HWID_list\nvfio-pci"

            if [[ -e $str_inFile3 ]]; then
                if [[ -e $str_outFile3 ]]; then
                    mv $str_outFile3 $str_oldFile3      # create backup
                fi

                touch $str_outFile3

                # write to file #
                while read -r str_line1; do
                    case $str_line1 in
                        *'#$str_output1'*)
                            str_line1=$str_output1;;
                        *'#$str_output2'*)
                            str_line1=$str_output2;;
                        *)
                            break;;
                    esac

                    echo -e $str_line1 >> $str_outFile3
                done < $str_inFile3
            else
                bool_missingFiles=true
            fi

        # /etc/modprobe.d/pci-blacklists.conf #
            str_output1=""

            for str_thisDriverName in ${arr_driverName_list[@]}; do
                str_output1+="blacklist $str_thisDriverName\n"
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
            str_output2="options vfio_pci ids=$str_HWID_list"

            if [[ -e $str_inFile5 ]]; then
                if [[ -e $str_outFile5 ]]; then
                    mv $str_outFile5 $str_oldFile5      # create backup
                fi

                touch $str_outFile5

                # write to file #
                while read -r str_line1; do
                    case $str_line1 in
                        *'#$str_output1'*)
                            str_line1=$str_output1;;
                        *'#$str_output2'*)
                            str_line1=$str_output2;;
                        *'#$str_output3'*)
                            str_line1=$str_output3;;
                        *)
                            break;;
                    esac

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
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VGA_VFIO[@]} -eq 0 ]]; then
                echo -e "$0: Executing Static setup... Cancelled. No IOMMU groups selected."
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Static setup... Complete."
            fi
    }

# debug prompt #
    # uncomment lines below #
    function DebugOutput {
        echo -e "$0: ========== DEBUG PROMPT ==========\n"

        ## lists ##
        # for (( i=0 ; i<${#arr_devices1[@]} ; i++ )); do echo -e "$0: '$""{arr_devices1[$i]}'\t= ${arr_devices1[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_devices2[@]} ; i++ )); do echo -e "$0: '$""{arr_devices2[$i]}'\t= ${arr_devices2[$i]}"; done && echo
        for (( i=0 ; i<${#arr_devices3[@]} ; i++ )); do echo -e "$0: '$""{arr_devices3[$i]}'\t= ${arr_devices3[$i]}"; done && echo
        #for (( i=0 ; i<${#arr_IOMMU_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_sum[$i]}'\t= ${arr_IOMMU_sum[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_busID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_busID_sum[$i]}'\t= ${arr_busID_sum[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_deviceName_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_deviceName_sum[$i]}'\t= ${arr_deviceName_sum[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_deviceType_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_deviceType_sum[$i]}'\t= ${arr_deviceType_sum[$i]}"; done && echo
        #for (( i=0 ; i<${#arr_driver_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_driver_sum[$i]}'\t= ${arr_driver_sum[$i]}"; done && echo
        #for (( i=0 ; i<${#arr_HWID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_HWID_sum[$i]}'\t= ${arr_HWID_sum[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_vendorName_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_vendorName_sum[$i]}'\t= ${arr_vendorName_sum[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_IOMMU_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host[$i]}'\t= ${arr_IOMMU_host[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_IOMMU_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO[$i]}'\t= ${arr_IOMMU_VFIO[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_IOMMU_VGA_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_host[$i]}'\t= ${arr_IOMMU_VGA_host[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_IOMMU_VGA_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VGA_VFIO[$i]}'\t= ${arr_IOMMU_VGA_VFIO[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_driver_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_driver_VFIO[$i]}'\t= ${arr_driver_VFIO[$i]}"; done && echo
        # for (( i=0 ; i<${#arr_HWID_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_HWID_VFIO[$i]}'\t= ${arr_HWID_VFIO[$i]}"; done && echo

        ## vars ##
        # echo -e "$0: '$'""{#arr_devices1[@]}\t= ${#arr_devices1[@]}"
        # echo -e "$0: '$'""{#arr_devices2[@]}\t= ${#arr_devices2[@]}"
        # echo -e "$0: '$'""{#arr_devices3[@]}\t= ${#arr_devices3[@]}"
        # echo -e "$0: '$'""{#arr_IOMMU_sum[@]}\t= ${#arr_IOMMU_sum[@]}"
        # echo -e "$0: '$'""{#arr_busID_sum[@]}\t= ${#arr_busID_sum[@]}"
        # echo -e "$0: '$'""{#arr_deviceName_sum[@]}\t= ${#arr_deviceName_sum[@]}"
        # echo -e "$0: '$'""{#arr_deviceType_sum[@]}\t= ${#arr_deviceType_sum[@]}"
        # echo -e "$0: '$'""{#arr_driver_sum[@]}\t= ${#arr_driver_sum[@]}"
        # echo -e "$0: '$'""{#arr_HWID_sum[@]}\t= ${#arr_HWID_sum[@]}"
        # echo -e "$0: '$'""{#arr_vendorName_sum[@]}\t= ${#arr_vendorName_sum[@]}"
        # echo -e "$0: '$'""{#arr_IOMMU_host[@]}\t= ${#arr_IOMMU_host[@]}"
        # echo -e "$0: '$'""{#arr_IOMMU_VFIO[@]}\t= ${#arr_IOMMU_VFIO[@]}"
        # echo -e "$0: '$'""{#arr_IOMMU_VGA_host[@]}\t= ${#arr_IOMMU_VGA_host[@]}"
        # echo -e "$0: '$'""{#arr_IOMMU_VGA_VFIO[@]}\t= ${#arr_IOMMU_VGA_VFIO[@]}"
        # echo -e "$0: '$'""{#arr_driver_VFIO[@]}\t= ${#arr_driver_VFIO[@]}"
        # echo -e "$0: '$'""{#arr_HWID_VFIO[@]}\t= ${#arr_HWID_VFIO[@]}"

        # echo -e "$0: '$""bool_existingSetup'\t\t= $bool_existingSetup"
        # echo -e "$0: '$""bool_hasVGA'\t\t= $bool_hasVGA"
        # echo -e "$0: '$""bool_hasExternalPCI'\t\t= $bool_hasExternalPCI"
        # echo -e "$0: '$""bool_missingFiles'\t\t= $bool_missingFiles"
        # echo -e "$0: '$""int_lastIOMMU'\t\t= $int_lastIOMMU"
        # echo -e "$0: '$""str_bootVGA_deviceName'\t\t= $str_bootVGA_deviceName"
        # echo -e "$0: '$""str_driver_VFIO_list'\t\t= $str_driver_VFIO_list"
        # echo -e "$0: '$""str_HWID_VFIO_list'\t\t= $str_HWID_VFIO_list"
        # echo -e "$0: '$""str_GRUB_CMDLINE'\t\t= $str_GRUB_CMDLINE"
        # echo -e "$0: '$""str_logFile0'\t\t= $str_logFile0"
        # echo -e "$0: '$""str_HWID_VFIO_list'\t\t= $str_HWID_VFIO_list"

        echo -e "\n$0: ========== DEBUG PROMPT =========="
        exit 0
    }

    #DebugOutput    # uncomment to debug here

# prompt #
    declare -i int_count=0                  # reset counter
    echo -en "$0: Deploy VFIO setup: Multi-Boot or Static?\n\t'Multi-Boot' is more flexible; adds multiple GRUB boot menu entries (each with one different, omitted IOMMU group).\n\t'Static', for unchanging setups.\n\t'Multi-Boot' is the recommended choice.\n"

    while [[ $bool_existingSetup == false || -z $bool_existingSetup || $bool_missingFiles == false ]]; do

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
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $bool_existingSetup
                echo
                sudo update-GRUB
                sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'"
                break;;
            "S")
                StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_existingSetup
                echo
                sudo update-grub
                sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'\n\t'$str_outFile2'\n\t'$str_outFile3'\n\t'$str_outFile4'\n\t'$str_outFile5'"
                break;;
            "N")
                echo -e "$0: Skipping."
                IFS=$SAVEIFS                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0;;
            *)
                echo -e "$0: Invalid input.";;
        esac

        ((int_count++))                     # increment counter
    done

    # warn user to delete existing setup and reboot to continue #
    if [[ $bool_existingSetup == true && $bool_missingFiles == false ]]; then
        echo -en "$0: Existing VFIO setup detected. "

        if [[ -e `find . -name *uninstall.bash*` ]]; then
            echo -e "To continue, execute `find . -name *uninstall.bash*` and reboot system."
        else
            echo -e "To continue, uninstall setup and reboot system."
        fi
    fi

    # warn user of missing files #
    if [[ $bool_missingFiles == true ]]; then
        echo -e "$0: Setup is not complete. Clone or re-download 'portellam/deploy-VFIO-setup' to continue."
    fi

IFS=$SAVEIFS                            # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0