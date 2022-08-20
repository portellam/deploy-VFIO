#!/bin/bash sh

exit 0

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1a.   Parse PCI and IOMMU groups, sort information to be parsed again later
# 2.    Choose setup. Existing VFIO setup, warn user, ask user to uninstall, and/or immediately exit.
# 3.    Ask user which valid IOMMU group to passthrough.
# 4a.   Static setup:       output to files and logfiles. No more input from user.
# 4b.   Multi-boot setup:   output to logfiles. Direct user to setup GRUB entries automaticcally.
# 5.    Update GRUB and INITRAMFS. Exit.
#
# NOTES:
# this is a rewrite of vfio-setup
# less convoluted, I bet it will be fewer lines when done too
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# parameters #
    readonly declare -a arr_devices1=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)
    readonly declare -a arr_devices2=(`lspci -m`)
    readonly declare -a arr_devices3=(`lspci -nk`)
    readonly declare -a arr_IOMMU_sum=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | cut -d '/' -f5 | sort -h`)
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
    str_bootVGA_deviceName=""
    str_driver_VFIO_list=""
    str_HWID_VFIO_list=""
    str_GRUB_CMDLINE=""
    str_GRUB_CMDLINE_Hugepages=""

# sort Bus ID by IOMMU group ID #
    for $element1 in ${arr_devices1[@]}; do
        for $str_IOMMU in ${arr_IOMMU_sum[@]}; do

            # match IOMMU group ID, save Bus ID #
            if [[ *$str_IOMMU* == $element1 ]]; then
                arr_busID_sum+=(`echo $element1 | cut -d '/' -f7`)
            fi
        done
    done

# sort devices' names and types by Bus ID and IOMMU group ID #
    for $element1 in ${arr_devices1[@]}; do
        for $str_BusID in ${arr_busID_sum[@]}; do
            str_thisBusID=`echo $element1 | cut -d ' ' -f1`

            # match #
            if [[ *$str_thisBusID* == $element1 ]]; then
                for $element2 in ${arr_devices2[@]}; do

                    # match #
                    if [[ $element2 == *$str_thisBusID* ]]; then
                        arr_deviceName_sum+=(`echo $element2 | cut -d '"' -f6`)
                        arr_deviceType_sum+=(`echo $element2 | cut -d '"' -f2`)
                        arr_vendorName_sum+=(`echo $element2 | cut -d '"' -f4`)
                    fi
                done
            fi
        done
    done

# sort devices' drivers and vendors by Bus ID and IOMMU group ID #
    for $str_BusID in ${arr_busID_sum[@]}; do
        bool_readNextLine=false

        for element1 in ${arr_devices3[@]}; do

            # false match driver, add HW ID to list #
            if [[ $bool_readNextLine == false && $element1 != *"driver"* ]]; then
                arr_vendorName_sum+=(`echo $element1 | grep "driver" | cut -d '"' -f1`)
            fi

            # match driver, add to list #
            if [[ $bool_readNextLine == true && $element1 == *"driver"* ]]; then

                # vfio driver found, exit #
                if [[ $str_thisDriver == 'vfio-pci' ]]; then
                    bool_existingSetup=true
                fi

                arr_driver_sum+=(str_thisDriver=`echo $element1 | grep "driver" | cut -d ' ' -f5`)
                bool_readNextLine=false
            fi

            # false match driver, add null to list #
            if [[ $bool_readNextLine == true && $element1 != *"driver"* ]]; then
                arr_driver_sum+=("NULL")
                bool_readNextLine=false
                break
            fi

            # match Bus ID, update boolean #
            if [[ $element1 == *$str_BusID* ]]; then
                bool_readNextLine=true
            fi
        done
    done

# add VFIO groups' w/o VGA (drivers and HWIDs) to lists #
    # MultiBoot, parse each VGA VFIO group for individual boot entries
    # Static, add all groups to new list
    for str_IOMMU in ${arr_IOMMU_VFIO[@]}; do
        for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do

            # match IOMMU group ID #
            if [[ $str_IOMMU == ${arr_IOMMU_sum[$int_i]} ]]; then
                arr_driver_VFIO+=(${arr_driver_sum[$int_i]})
                arr_HWID_VFIO+=(${arr_HWID_sum[$int_i]})
                str_driver_VFIO_list+=(${arr_driver_sum[$int_i]})","
                str_HWID_VFIO_list+=(${arr_HWID_sum[$int_i]})","
            fi
        done
    done

# change parameters #
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

# Parse and Prompt PCI devices #
    #
    # TODO:
    #
    #   -prompt user with warning
    #   -parse all IOMMU groups
    #   -ask user to passthrough a IOMMU group, at each
    #   -save output
    #   -
    #
    #
    ParsePCI {

        # list IOMMU groups #
            str_output1="$0: PLEASE READ: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.
            \n\t\tDevices that share IOMMU groups must be passed-through as whole or none at all.
            \n\t\tEvaluate order of PCI slots to have PCI devices in individual IOMMU groups.
            \n\t\tA feature (ACS-Override patch) exists to divide IOMMU groups, but said feature creates an attack vector (memory read/write across PCI devices) and is not recommended (for security reasons).
            \n\t\tSome onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n\n$0: Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not.\n"

        echo -e $str_output1

        # passthrough IOMMU group ID by user descretion #
            for str_IOMMU in ${arr_IOMMU_sum[@]}; do
                declare -a arr_thisIOMMU

                for (( int_i=0 ; int_i<${#arr_IOMMU_sum[@]} ; int_i++ )); do
                    str_thisIOMMU=${arr_IOMMU_sum[$int_i]}

                    if [[ $str_thisIOMMU == $str_IOMMU ]]; then
                        arr_thisIOMMU+=($int_i)
                    fi
                done

                # match Bus ID and device type #
                for (( int_i=0 ; int_i<${#arr_thisIOMMU[@]} ; int_i++ )); do
                    str_thisDeviceType=`echo $str_element2 | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`

                    if [[ $str_thisDeviceType == *"VGA"* && $str_thisDeviceType == *"GRAPHICS"* ]]; then
                        bool_hasVGA=true
                    fi

                    if [[ `echo ${arr_busID_sum[$int_i]} | cut -d ':' -f2` -ge 1 ]]; then
                        bool_hasExternalPCI=true
                    fi

                    if [[ $bool_hasVGA == true && $bool_hasExternalPCI == true ]]; then
                        str_bootVGA_deviceName=${arr_deviceName_sum[$int_i]}
                    fi
                done

                # prompt #
                echo

                if [[ $bool_hasExternalPCI == true ]]; then
                    echo -e "\tIOMMU:\t\t$str_IOMMU"

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

                    echo -en "Select IOMMU group ID '$str_IOMMU'? [Y/n]: "
                    read str_input1

                    if [[ $str_input1 == "Y"* && $bool_hasVGA == false ]]; then
                        arr_IOMMU_VFIO+=$str_IOMMU
                        echo "Selected IOMMU group ID '$str_IOMMU'."
                    fi

                    if [[ $str_input1 == "Y"* && $bool_hasVGA == true ]]; then
                        echo "Selected IOMMU group ID '$str_IOMMU'."
                        arr_IOMMU_VGA_VFIO+=$str_IOMMU
                    fi

                    if [[ $str_input1 == "N"* && $bool_hasVGA == false ]]; then
                        arr_IOMMU_host+=$str_IOMMU
                    fi

                    if [[ $str_input1 == "N"* && $bool_hasVGA == true ]]; then
                        arr_IOMMU_VGA_host+=$str_IOMMU
                    fi
                else
                    echo -e "IOMMU group ID '$str_IOMMU' has no External PCI devices. Skipping."
                fi

                bool_hasVGA=false
                bool_hasExternalPCI=false
            done
    }

# Multi boot setup #
    MultiBootSetup {

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
                            WriteToFile {

                                if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then

                                    # write to tempfile #
                                    echo -e \n\n $str_line1 >> $str_outFile1
                                    echo -e \n\n $str_line1 >> $str_logFile1
                                    while read -r str_line1; do
                                        if [[ $str_line1 == *'#$str_output1'* ]]; then
                                            str_line1=$str_output1
                                            echo -e $str_output1_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == *'#$str_output2'* ]]; then
                                            str_line1=$str_output2
                                        fi

                                        if [[ $str_line1 == *'#$str_output3'* ]]; then
                                            str_line1=$str_output3
                                        fi

                                        if [[ $str_line1 == *'#$str_output4'* ]]; then
                                            str_line1=$str_output4
                                        fi

                                        if [[ $str_line1 == *'#$str_output5'* ]]; then
                                            str_line1=$str_output5
                                            echo -e $str_output5_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == *'#$str_output6'* ]]; then
                                            str_line1=$str_output6
                                            echo -e $str_output6_log >> $str_logFile1
                                        fi

                                        if [[ $str_line1 == *'#$str_output7'* ]]; then
                                            str_line1=$str_output7
                                            echo -e $str_output7_log >> $str_logFile1
                                        fi

                                        echo -e $str_line1 >> $str_outFile1
                                        echo -e $str_line1 >> $str_logFile1
                                    done < $str_inFile1b        # read from template
                                else
                                    bool_missingFiles=true
                                fi
                        }

                    # new parameters #
                        str_GRUB_CMDLINE="${str_GRUB_CMDLINE_prefix} ${str_GRUB_CMDLINE_Hugepages} modprobe.blacklist=${str_driver_VFIO_thisList} vfio_pci.ids=${str_HWID_VFIO_thisList}"

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

                            WriteToFile     # call function
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
            elif [[ ${#arr_IOMMU_VGAlist[@]} -le 0 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups with VGA devices passed-through."
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Multi-boot setup... Complete."
            fi
    }

# Static setup #
    StaticSetup {

        echo -e "$0: Executing Static setup..."
        ParsePCI                                 call function

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
                str_logFile0=`find $(pwd) -name *hugepages*log*`
                str_logFile1=$(pwd)"/grub.log"
                # none for file2-file5

            # clear files #     # NOTE: do NOT delete GRUB !!!
                if [[ -e $str_logFile1 ]]; then rm $str_logFile1; fi
                if [[ -e $str_logFile5 ]]; then rm $str_logFile5; fi
    }

# prompt #
    echo -en "$0: "
    declare -i int_count=0                  # reset counter
    str_prompt="$0: Deploy VFIO setup: Multi-Boot or Static?\n\t'Multi-Boot' is more flexible; adds multiple GRUB boot menu entries (each with one different, omitted IOMMU group).\n\t'Static', for unchanging setups.\n\t'Multi-Boot' is the recommended choice.\n"

    if [[ -z $str_input1 ]]; then
        echo -e $str_prompt
    fi

    while [[ $bool_existingSetup == false || -z $bool_existingSetup || $bool_missingFiles == false ]]; do
        if [[ $int_count -ge 3 ]]; then
            echo -en "Exceeded max attempts."
            str_input1="N"                  # default selection
        else
            echo -en "Deploy VFIO setup? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
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
                exit 0
                ;;
            *)
                echo -en "$0: Invalid input.";;
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