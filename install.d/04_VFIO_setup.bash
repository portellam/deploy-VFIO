#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

#
# TO-DO:
#   - hide 'grep' error, possibly occurs during vfio driver/hw id parse in either setup
#   - change logfile ownership to home folder owner
#
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        str_input1=${str_input1:0:1}
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!
            else
                echo -en "\t$str_output1"
                read str_input1

                str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                str_input1=${str_input1:0:1}
            fi

            case $str_input1 in
                "Y"|"N")
                    break;;
                *)
                    echo -en "\tInvalid input. ";;
            esac

            ((int_count++))         # increment counter
        done
    }

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "install.d" ]]; then
        if [[ -e `find . -name install.d` ]]; then
            # echo -e "Script located the correct working directory."
            cd `find . -name install.d`
        else
            echo -e "WARNING: Script cannot locate the correct working directory.\n\tExiting."
        fi
    # else
    #     echo -e "Script is in the correct working directory."
    fi

# GRUB: hugepages check #
    str_file=`find .. -name *Hugepages*log*`

    if [[ -z $str_file ]]; then
        str_file=`find . -name *Hugepages*bash*`
        str_file=`echo ${str_file##/*} | cut -d '/' -f2`
        echo -e "WARNING: Logfile does not exist.\n\tShould you wish to allocate Hugepages, execute '$str_file', then '$0'.\n"
    else
        readonly str_HugePageSize=`cat $str_file | cut -d '#' -f2 | cut -d ' ' -f1`
        readonly str_HugePageSum=`cat $str_file | cut -d '#' -f3`
        readonly str_GRUB_CMDLINE_Hugepages="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${str_HugePageSum}"
    fi

# GRUB: isolate CPUs check #
    str_file=`find .. -name *Isolate_CPU*log*`

    # if [[ -z $str_file ]]; then
    #     str_file=`find . -name *Isolate_CPU*bash*`
    #     str_file=`echo ${str_file##/*} | cut -d '/' -f2`
    #     echo -e "WARNING: Logfile does not exist.\n\tShould you wish to allocate CPU threads, execute '$str_file', then '$0'.\n"
    # else
    #     readonly str_HugePageSize=`cat $str_file | cut -d '#' -f2 | cut -d ' ' -f1`
    #     readonly str_HugePageSum=`cat $str_file | cut -d '#' -f3`
    #     readonly str_GRUB_CMDLINE_Hugepages="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${str_HugePageSum}"
    # fi

# parameters #
    declare -a arr_IOMMU_host=()
    declare -a arr_IOMMU_hostVGA=()
    declare -a arr_IOMMU_VFIO=()
    declare -a arr_IOMMU_VFIOVGA=()
    declare -a arr_typeIsVGA_IOMMU=()
    bool_driverIsValid=false
    bool_foundExistingVFIOsetup=false
    bool_IOMMUcontainsExtPCI=false
    bool_IOMMUcontainsVGA=false
    bool_outputToGRUB=false
    str_internalPCI_driverList=""
    str_internalPCI_HWIDList=""
    str_PCISTUB_driverList=""
    str_IGPUFullName=""

    # NOTE: update here!
    str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off,vesafb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 ${str_GRUB_CMDLINE_Hugepages}"

# multi-boot setup #
    function MultiBootSetup
    {
        echo -e "Executing Multi-boot setup..."

        # parse IOMMU #
            shopt -s nullglob
            for str_line0 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                # parameters #
                bool_driverIsValid=false
                bool_IOMMUcontainsExtPCI=false
                bool_IOMMUcontainsVGA=false
                declare -i int_thisIOMMU=`echo $str_line0 | cut -d '/' -f5`
                str_input1=""
                echo -e "IOMMU Group: '$int_thisIOMMU'"

                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`
                    str_thisType=`lspci -mmd $str_thisHWID | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`
                    str_line3=`lspci -nnkd $str_thisHWID | grep -Eiv "DeviceName:|Kernel modules:|Subsystem:"`

                    if [[ $str_thisDriver == *"vfio"* ]]; then
                        bool_foundExistingVFIOsetup=true
                    fi

                    if [[ -z $str_thisDriver || $str_thisDriver == "" ]]; then
                        str_thisDriver="N/A"
                        bool_driverIsValid=false
                    else
                        bool_driverIsValid=true
                    fi

                    # save all internal PCI drivers to list #
                    # parse this list to exclude these devices from blacklist
                    # example: 'snd_hda_intel' is used by on-board audio devices and VGA audio child devices
                    if [[ ${str_thisBusID::1} == "0" && ${str_thisBusID:1:1} -lt 1 ]]; then
                        str_internalPCI_driverList+="$str_thisDriver,"
                        str_internalPCI_HWIDList+="$str_thisHWID,"
                        bool_IOMMUcontainsExtPCI=false
                    else
                        bool_IOMMUcontainsExtPCI=true
                    fi

                    # save all IOMMU groups that contain VGA device(s) #
                    # parse this list for 'Multi-boot' function later on
                    if [[ $str_thisType == *"3D"* || $str_thisType == *"DISPLAY"* || $str_thisType == *"GRAPHIC"* || $str_thisType == *"VGA"* ]]; then
                        bool_IOMMUcontainsVGA=true
                    fi

                    # save drivers (of given device type) for 'pci-stub' (not 'vfio-pci') #
                    # parse this list for 'Multi-boot' function later on
                    # Why? Bind devices earlier than 'vfio-pci'
                    # GRUB:             parse this list and append to pci-stub
                    # system files:     parse this list and append to vfio-pci
                    if [[ $str_thisType == *"USB"* ]]; then                     # NOTE: update here!
                        str_PCISTUB_driverList+="$str_thisDriver,"
                    fi

                    # parse IOMMU if it cotains external PCI #
                    if [[ $bool_IOMMUcontainsExtPCI == true ]]; then
                        if [[ $bool_driverIsValid == false ]]; then
                            str_line3+="\n\tKernel driver in use: N/A"
                        fi

                        echo -e "\t$str_line3\n"

                    # save IGPU vendor and device name #
                    else
                        if [[ $bool_IOMMUcontainsVGA == true ]]; then
                            str_IGPUFullName=`lspci -mmn | grep $str_thisBusID | cut -d '"' -f4``lspci -mmn | grep $str_thisBusID | cut -d '"' -f6`
                        fi
                    fi
                done;

                # prompt #
                str_output2=""

                if [[ $bool_IOMMUcontainsExtPCI == false ]]; then
                    str_output2="Skipped IOMMU group: External devices not found."
                else
                    str_output1="Select IOMMU group '$int_thisIOMMU'? [Y/n]: "
                    ReadInput $str_output1

                    if [[ $bool_IOMMUcontainsVGA == false ]]; then
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIO+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;
                            "N")
                                arr_IOMMU_host+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;
                            *)
                                str_output2="Invalid input.";;
                        esac
                    else
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIOVGA+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;
                            "N")
                                arr_IOMMU_hostVGA+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;
                            *)
                                str_output2="Invalid input.";;
                        esac
                    fi
                fi

                echo -e "\t$str_output2\n"
            done;

            if [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VFIOVGA[@]} -eq 0 ]]; then
                echo -e "Executing Multi-boot setup... Cancelled. No IOMMU groups selected."
                exit 0
            fi

        # parameters #
            readonly str_thisFile="${0##*/}"
            readonly str_logFile0="$str_thisFile.log"
            declare -a arr_VFIO_driver=()
            declare -a arr_VFIOVGA_driver=()
            str_thisFullName=""

            readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
            declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3`)     # first three kernels
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
            readonly str_inFile1b=`find . -name *Multi-boot_template`

            # comment to debug here #
            readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"

            # uncomment to debug here #
            readonly str_oldFile1="$str_outFile1.old"

            # create backup #
            if [[ -e $str_outFile1 ]]; then
                mv $str_outFile1 $str_oldFile1
            fi

            # restore backup #
            if [[ -e $str_inFile1 ]]; then
                cp $str_inFile1 $str_outFile1
            fi

            # create logfile #
            if [[ -e $str_logFile0 ]]; then
                rm $str_logFile0
            else
                touch $str_logFile0
            fi

        # parse VFIO IOMMU group(s) #
        for int_IOMMU_VFIO in ${arr_IOMMU_VFIO[@]}; do
            for str_line0 in `find /sys/kernel/iommu_groups/$int_IOMMU_VFIO -maxdepth 0 -type d | sort -V`; do
                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`

                    # add to lists #
                    if [[ $str_thisDriver != "" ]]; then
                        if [[ -z `echo $str_internalPCI_driverList | grep $str_thisDriver` && -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                            if [[ ${#str_VFIO_driverList[@]} != 0 && -z `echo $str_VFIO_driverList | grep $str_thisDriver` ]]; then
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"

                            else
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"
                            fi
                        fi
                    fi

                    if [[ -z `echo $str_internalPCI_HWIDList | grep $str_thisHWID` && -z `echo $str_VFIO_HWIDList | grep $str_thisHWID` ]]; then
                        if [[ ${#str_PCISTUB_HWIDlist[@]} != 0 && -z `echo $str_PCISTUB_HWIDlist | grep $str_thisHWID` ]]; then
                            if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi

                        else

                            if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi
                        fi
                    fi
                done
            done
        done

        # parse VFIO IOMMU group(s) with VGA device(s) #
        for int_IOMMU_VFIOVGA in ${arr_IOMMU_VFIOVGA[@]}; do

            # update parameters #
            str_PCISTUBVGA_HWIDlist=""
            str_VFIOVGA_driverList=""
            str_VFIOVGA_HWIDList=""

            for str_line0 in `find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`; do

                # parameters #
                declare -i int_thisIOMMU=`echo $str_line0 | cut -d '/' -f5`

                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`
                    str_thisType=`lspci -mmd $str_thisHWID | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`

                    # add to lists #
                    if [[ $int_thisIOMMU != $int_IOMMU_VFIOVGA ]]; then
                        if [[ $str_thisDriver != "" ]]; then
                            if [[ -z `echo $str_internalPCI_driverList | grep $str_thisDriver` && -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` && -z `echo $str_VFIO_driverList | grep $str_thisDriver` && -z `echo $str_VFIOVGA_driverList | grep $str_thisDriver` ]]; then
                                arr_VFIOVGA_driver+=("$str_thisDriver")
                                str_VFIOVGA_driverList+="$str_thisDriver,"
                            fi
                        fi

                        if [[ -z `echo $str_internalPCI_HWIDList | grep $str_thisHWID` && -z `echo $str_PCISTUB_HWIDlist | grep $str_thisHWID` && -z `echo $str_VFIO_HWIDList | grep $str_thisHWID` ]]; then
                            if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                                str_PCISTUBVGA_HWIDlist+="$str_thisHWID,"
                            else
                                str_VFIOVGA_HWIDList+="$str_thisHWID,"
                            fi
                        fi

                    # save VGA vendor and device name #
                    else
                        if [[ $str_thisType == *"3D"* || $str_thisType == *"DISPLAY"* || $str_thisType == *"GRAPHIC"* || $str_thisType == *"VGA"* ]]; then
                            str_thisFullName=`lspci -mnn | grep $str_thisBusID | cut -d '"' -f4`" "`lspci -mnn | grep $str_thisBusID | cut -d '"' -f6`
                        fi
                    fi
                done
            done

            # update parameters #
            str_thisPCISTUB_HWIDList=${str_PCISTUB_HWIDlist}${str_PCISTUBVGA_HWIDlist}
            str_thisVFIO_driverList=${str_VFIO_driverList}${str_VFIOVGA_driverList}
            str_thisVFIO_HWIDList=${str_VFIO_HWIDList}${str_VFIOVGA_HWIDList}

            # remove last separator #
            if [[ ${str_thisPCISTUB_HWIDList: -1} == "," ]]; then
                str_thisPCISTUB_HWIDList=${str_thisPCISTUB_HWIDList::-1}
            fi

            if [[ ${str_thisVFIO_driverList: -1} == "," ]]; then
                str_thisVFIO_driverList=${str_thisVFIO_driverList::-1}
            fi

            if [[ ${str_thisVFIO_HWIDList: -1} == "," ]]; then
                str_thisVFIO_HWIDList=${str_thisVFIO_HWIDList::-1}
            fi

            # write to file #

                # parameters #
                if [[ $str_IGPUFullName != "N/A" && $str_IGPUFullName != "" ]]; then
                    str_thisFullName=$str_IGPUFullName
                fi

                # update parameters #
                if [[ ${str_thisFullName: -1} == " " ]]; then
                    str_thisFullName=${str_thisFullName::-1}
                fi

                # NOTE: update here!
                str_GRUB_CMDLINE="${str_GRUB_CMDLINE_prefix} modprobe.blacklist=${str_thisVFIO_driverList} pci-stub.ids=${str_thisPCISTUB_HWIDList} vfio_pci.ids=${str_thisVFIO_HWIDList}"

                # log file #
                echo -e "#${int_IOMMU_VFIOVGA} #${str_thisFullName} #${str_GRUB_CMDLINE}" >> $str_logFile0

                ## /etc/grub.d/proxifiedScripts/custom ##

                    # parse kernels #
                    for (( int_i=0 ; int_i<${#arr_rootKernel[@]} ; int_i++)); do

                        # match #
                        if [[ -e ${arr_rootKernel[$int_i]} || ${arr_rootKernel[$int_i]} != "" ]]; then
                            str_thisRootKernel=${arr_rootKernel[$int_i]:1}

                            # parameters #
                            str_output1='menuentry "'"`lsb_release -i -s` `uname -o`, with `uname` $str_thisRootKernel (VFIO, w/o IOMMU '$int_IOMMU_VFIOVGA', w/ boot VGA '$str_thisFullName'\") {"
                            str_output1_log="\n"'menuentry "'"`lsb_release -i -s` `uname -o`, with `uname` #kernel_'$int_i'# (VFIO, w/o IOMMU '$int_IOMMU_VFIOVGA', w/ boot VGA '$str_thisFullName'\") {"
                            str_output2="\tinsmod $str_rootFSTYPE"
                            str_output3="\tset root='/dev/disk/by-uuid/$str_rootUUID'"
                            str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"$str_rootUUID\n\t"'fi'
                            str_output5="\techo    'Loading Linux $str_thisRootKernel ...'"
                            str_output5_log="\techo    'Loading Linux #kernel'$int_i'# ...'"
                            str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                            str_output6_log="\tlinux   /boot/vmlinuz-#kernel'$int_i'# root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                            str_output7="\tinitrd  /boot/initrd.img-$str_thisRootKernel"
                            str_output7_log="\tinitrd  /boot/initrd.img-"'#kernel'$int_i'#'

                            # debug prompt #
                            # echo -e "'$""str_output0'\t\t= $str_output0"
                            # echo -e "'$""str_output1'\t\t= $str_output1"
                            # echo -e "'$""str_output2'\t\t= $str_output2"
                            # echo -e "'$""str_output3'\t\t= $str_output3"
                            # echo -e "'$""str_output4'\t\t= $str_output4"
                            # echo -e "'$""str_output5'\t\t= $str_output5"
                            # echo -e "'$""str_output6'\t\t= $str_output6"
                            # echo -e "'$""str_output7'\t\t= $str_output7"
                            # echo

                            if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then

                                # write to tempfile #
                                echo -e >> $str_outFile1

                                while read -r str_line1; do
                                    case $str_line1 in

                                        *'#$str_output1'*)
                                            str_outLine1="$str_output1";;

                                        *'#$str_output2'*)
                                            str_outLine1="$str_output2";;

                                        *'#$str_output3'*)
                                            str_outLine1="$str_output3";;

                                        *'#$str_output4'*)
                                            str_outLine1="$str_output4";;

                                        *'#$str_output5'*)
                                            str_outLine1="$str_output5";;

                                        *'#$str_output6'*)
                                            str_outLine1="$str_output6";;

                                        *'#$str_output7'*)
                                            str_outLine1="$str_output7";;

                                        *)
                                            str_outLine1="$str_line1";;
                                    esac

                                    # write to system file and logfile (post_install: update Multi-boot) #
                                    echo -e "$str_outLine1" >> $str_outFile1
                                done < $str_inFile1b        # read from template
                            else
                                bool_missingFiles=true
                            fi
                        fi
                    done

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                echo -e "File(s) missing:"

                if [[ -z $str_inFile1 ]]; then
                    echo -e "\t'$str_inFile1'"
                fi

                if [[ -z $str_inFile1b ]]; then
                    echo -e "\t'$str_inFile1b'"
                fi

                echo -e "Executing Multi-boot setup... Failed."
                exit 0

            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "Executing Multi-boot setup... Complete."
            fi
        done
    }

# static setup #
    function StaticSetup
    {
        echo -e "Executing Static setup..."

        # parse IOMMU #
            shopt -s nullglob
            for str_line0 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                # parameters #
                bool_driverIsValid=false
                bool_IOMMUcontainsExtPCI=false
                bool_IOMMUcontainsVGA=false
                declare -i int_thisIOMMU=`echo $str_line0 | cut -d '/' -f5`
                str_input1=""
                echo -e "IOMMU Group: '$int_thisIOMMU'"

                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`
                    str_thisType=`lspci -mmd $str_thisHWID | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]'`
                    str_line3=`lspci -nnkd $str_thisHWID | grep -Eiv "DeviceName:|Kernel modules:|Subsystem:"`

                    if [[ $str_thisDriver == *"vfio"* ]]; then
                        bool_foundExistingVFIOsetup=true
                    fi

                    if [[ -z $str_thisDriver || $str_thisDriver == "" ]]; then
                        str_thisDriver="N/A"
                        bool_driverIsValid=false
                    else
                        bool_driverIsValid=true
                    fi

                    # save all internal PCI drivers to list #
                    # parse this list to exclude these devices from blacklist
                    # example: 'snd_hda_intel' is used by on-board audio devices and VGA audio child devices
                    if [[ ${str_thisBusID::1} == "0" && ${str_thisBusID:1:1} -lt 1 ]]; then
                        str_internalPCI_driverList+="$str_thisDriver,"
                        str_internalPCI_HWIDList+="$str_thisHWID,"
                        bool_IOMMUcontainsExtPCI=false
                    else
                        bool_IOMMUcontainsExtPCI=true
                    fi

                    # save all IOMMU groups that contain VGA device(s) #
                    # parse this list for 'Multi-boot' function later on
                    if [[ $str_thisType == *"3D"* || $str_thisType == *"DISPLAY"* || $str_thisType == *"GRAPHIC"* || $str_thisType == *"VGA"* ]]; then
                        bool_IOMMUcontainsVGA=true
                    fi

                    # save drivers (of given device type) for 'pci-stub' (not 'vfio-pci') #
                    # parse this list for 'Multi-boot' function later on
                    # Why? Bind devices earlier than 'vfio-pci'
                    # GRUB:             parse this list and append to pci-stub
                    # system files:     parse this list and append to vfio-pci
                    if [[ $str_thisType == *"USB"* ]]; then                     # NOTE: update here!
                        str_PCISTUB_driverList+="$str_thisDriver,"
                    fi

                    # parse IOMMU if it cotains external PCI #
                    if [[ $bool_IOMMUcontainsExtPCI == true ]]; then
                        if [[ $bool_driverIsValid == false ]]; then
                            str_line3+="\n\tKernel driver in use: N/A"
                        fi

                        echo -e "\t$str_line3\n"

                    # save IGPU vendor and device name #
                    else
                        if [[ $bool_IOMMUcontainsVGA == true ]]; then
                            str_IGPUFullName=`lspci -mmn | grep $str_thisBusID | cut -d '"' -f4``lspci -mmn | grep $str_thisBusID | cut -d '"' -f6`
                        fi
                    fi
                done;

                # prompt #
                str_output2=""

                if [[ $bool_IOMMUcontainsExtPCI == false ]]; then
                    str_output2="Skipped IOMMU group: External devices not found."
                else
                    str_output1="Select IOMMU group '$int_thisIOMMU'? [Y/n]: "
                    ReadInput $str_output1

                    if [[ $bool_IOMMUcontainsVGA == false ]]; then
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIO+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;

                            "N")
                                arr_IOMMU_host+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;

                            *)
                                str_output2="Invalid input.";;
                        esac
                    else
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIOVGA+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;

                            "N")
                                arr_IOMMU_hostVGA+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;

                            *)
                                str_output2="Invalid input.";;
                        esac
                    fi
                fi

                echo -e "\t$str_output2\n"
            done;

            if [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VFIOVGA[@]} -eq 0 ]]; then
                echo -e "Executing Static setup... Cancelled. No IOMMU groups selected."
                exit 0
            fi

            if [[ ${#arr_IOMMU_hostVGA[@]} -eq 0 ]]; then
                echo -e "Executing Static setup... Cancelled. No VGA device(s) available to host OS."
                exit 0
            fi

        # parameters #
            declare -a arr_VFIO_driver=()
            declare -a arr_VFIOVGA_driver=()
            bool_missingFiles=false
            str_PCISTUB_HWIDlist=""
            str_VFIO_driver_softdep=""
            str_VFIO_driverList=""
            str_VFIO_HWIDList=""

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

        # prompt #
        str_output1="Append changes to '/etc/default/grub' or no (system files)? [Y/n]: "
        ReadInput $str_output1

        case $str_input1 in
            "Y")
                bool_outputToGRUB=true;;

            "N")
                bool_outputToGRUB=false;;
        esac

        echo

        # parse VFIO IOMMU group(s) #
        for int_thisIOMMU in ${arr_IOMMU_VFIO[@]}; do
            for str_line0 in `find /sys/kernel/iommu_groups/$int_thisIOMMU -maxdepth 0 -type d | sort -V`; do
                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`

                    # add to lists #
                    if [[ $str_thisDriver != "" ]]; then
                        if [[ -z `echo $str_internalPCI_driverList | grep $str_thisDriver` && -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                            if [[ ${#str_VFIO_driverList[@]} != 0 && -z `echo $str_VFIO_driverList | grep $str_thisDriver` ]]; then
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"

                            else
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"
                            fi
                        fi
                    fi

                    if [[ -z `echo $str_internalPCI_HWIDList | grep $str_thisHWID` && -z `echo $str_VFIO_HWIDList | grep $str_thisHWID` ]]; then
                        if [[ ${#str_PCISTUB_HWIDlist[@]} != 0 && -z `echo $str_PCISTUB_HWIDlist | grep $str_thisHWID` ]]; then
                            if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi

                        else
                            if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi
                        fi
                    fi
                done
            done
        done

        # parse VFIO IOMMU group(s) with VGA device(s) #
        for int_thisIOMMU in ${arr_IOMMU_VFIOVGA[@]}; do
            for str_line0 in `find /sys/kernel/iommu_groups/$int_thisIOMMU -maxdepth 0 -type d | sort -V`; do
                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=`lspci -mns ${str_line1##*/}`
                    str_thisBusID=`echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1`
                    str_thisHWID=`lspci -n | grep $str_thisBusID | cut -d ' ' -f3`
                    str_thisDriver=`lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2`

                    # add to lists #
                    if [[ $str_thisDriver != "" ]]; then
                        if [[ -z `echo $str_internalPCI_driverList | grep $str_thisDriver` && -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                            arr_VFIO_driver+=("$str_thisDriver")
                            str_VFIO_driverList+="$str_thisDriver,"
                        fi
                    fi

                    if [[ -z `echo $str_internalPCI_HWIDList | grep $str_thisHWID` ]]; then
                        if [[ ! -z `echo $str_PCISTUB_driverList | grep $str_thisDriver` ]]; then
                            str_PCISTUB_HWIDlist+="$str_thisHWID,"

                        else
                            str_VFIO_HWIDList+="$str_thisHWID,"
                        fi
                    fi
                done
            done
        done

        # update parameters #
        if [[ ${str_VFIO_driverList: -1} == "," ]]; then
            str_VFIO_driverList=${str_VFIO_driverList::-1}
        fi

        if [[ ${str_VFIO_HWIDList: -1} == "," ]]; then
            str_VFIO_HWIDList=${str_VFIO_HWIDList::-1}
        fi

        # VFIO soft dependencies #

        # parse VFIO groups #
        for str_thisDriver in ${arr_VFIO_driver[@]}; do

            # false match internal device #
            if [[ $str_thisDriver != *"$str_internalPCI_driverList"* ]]; then
                str_VFIO_driver_softdep+="\nsoftdep $str_thisDriver pre: vfio-pci"
                str_VFIO_driver_softdepFull+="\nsoftdep $str_thisDriver pre: vfio-pci\n$str_thisDriver"
            fi
        done

        # parse VFIO VGA groups #
        for str_thisDriver in ${arr_VFIOVGA_driver[@]}; do

            # false match internal device #
            if [[ $str_thisDriver != *"$str_internalPCI_driverList"* ]]; then
                str_VFIO_driver_softdep+="\nsoftdep $str_thisDriver pre: vfio-pci"
                str_VFIO_driver_softdepFull+="\nsoftdep $str_thisDriver pre: vfio-pci\n$str_thisDriver"
            fi
        done

        # write to files #
        if [[ $bool_outputToGRUB == true ]]; then

            # update parameters #
            if [[ ${str_PCISTUB_HWIDlist: -1} == "," ]]; then
                str_PCISTUB_HWIDlist=${str_PCISTUB_HWIDlist::-1}
            fi

            # /etc/default/grub #
            str_GRUB_CMDLINE+="${str_GRUB_CMDLINE_prefix} modprobe.blacklist=${str_VFIO_driverList} pci-stub.ids=${str_PCISTUB_HWIDlist} vfio_pci.ids=${str_VFIO_HWIDList}"

            cp $str_inFile2 $str_outFile2
            cp $str_inFile3 $str_outFile3
            cp $str_inFile4 $str_outFile4
            cp $str_inFile5 $str_outFile5
        else

            # /etc/default/grub #
            str_GRUB_CMDLINE+="${str_GRUB_CMDLINE_prefix} modprobe.blacklist= pci-stub.ids= vfio_pci.ids="

            # /etc/modules #
                str_output1="vfio_pci ids=${str_PCISTUB_HWIDlist}${str_VFIO_HWIDList}"

                if [[ -e $str_inFile2 ]]; then
                    if [[ -e $str_outFile2 ]]; then
                        # mv $str_outFile2 $str_oldFile2      # create backup
                        rm $str_outFile2
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
                str_output1=$str_VFIO_driver_softdepFull
                str_output2="options vfio_pci ids=${str_PCISTUB_HWIDlist}${str_VFIO_HWIDList}\nvfio_pci ids=${str_PCISTUB_HWIDlist}${str_VFIO_HWIDList}\nvfio-pci"

                if [[ -e $str_inFile3 ]]; then
                    if [[ -e $str_outFile3 ]]; then
                        # mv $str_outFile3 $str_oldFile3      # create backup
                        rm $str_outFile3
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

                for str_thisDriver in ${arr_VFIO_driver[@]}; do
                    str_output1+="blacklist $str_thisDriver\n"
                done

                if [[ -e $str_inFile4 ]]; then
                    if [[ -e $str_outFile4 ]]; then
                        # mv $str_outFile4 $str_oldFile4      # create backup
                        rm $str_outFile4
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
                str_output1="$str_VFIO_driver_softdep"
                str_output2="options vfio_pci ids=${str_PCISTUB_HWIDlist}${str_VFIO_HWIDList}"

                if [[ -e $str_inFile5 ]]; then
                    if [[ -e $str_outFile5 ]]; then
                        # mv $str_outFile5 $str_oldFile5      # create backup
                        rm $str_outFile5
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
        fi

        # /etc/default/grub #
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

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                bool_missingFiles=true
                echo -e "File(s) missing:"

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

                echo -e "Executing Static setup... Failed."
                exit 0

            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "Executing Static setup... Complete."
            fi
    }

# prompt #
    echo -e "'Multi-boot' is a flexible VFIO setup:\n\tinstallation appends different combinations of IOMMU groups to a GRUB menu entry;\n\tthe user may select the preferred host graphics (VGA) device at GRUB boot menu.\n\t'Static' is a 'permanent' VFIO setup:\n\tinstallation may append to system files. 'Static' survives kernel upgrades (without help of the 'post-install' updater).\n\tMulti-boot is the recommended choice.\n"

    declare -i int_count=0                  # reset counter

    while [[ $bool_foundExistingVFIOsetup == false || -z $bool_foundExistingVFIOsetup || $bool_missingFiles == false ]]; do
        if [[ $int_count -ge 3 ]]; then
            echo -e "Exceeded max attempts."
            str_input1="N"                  # default selection
        else
            echo -en "Deploy VFIO setup? [ (M)ulti-boot / (S)tatic / (N)one ]: "
            read -r str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
        fi

        case $str_input1 in
            "M")
                echo
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $bool_foundExistingVFIOsetup
                echo
                sudo update-grub
                echo -e "\nReview changes:\n\t'$str_outFile1'"
                break;;

            "S")
                echo
                StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_foundExistingVFIOsetup
                echo
                sudo update-grub
                sudo update-initramfs -u -k all

                if [[ $bool_outputToGRUB == true ]]; then
                    echo -e "\nReview changes:\n\t'$str_outFile1'"
                else
                    echo -e "\nReview changes:\n\t'$str_outFile1'\n\t'$str_outFile2'\n\t'$str_outFile3'\n\t'$str_outFile4'\n\t'$str_outFile5'"
                fi

                break;;

            "N")
                IFS=$SAVEIFS                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0;;

            *)
                echo -e "Invalid input. ";;
        esac

        ((int_count++))                     # increment counter
    done

    # warn user to delete existing setup and reboot to continue #
    if [[ $bool_foundExistingVFIOsetup == true && $bool_missingFiles == false ]]; then
        echo -en "Existing VFIO setup detected. "

        if [[ -e `find .. -name *uninstall.bash*` ]]; then
            echo -e "To continue, execute `find .. -name *uninstall.bash*` and reboot system."
        else
            echo -e "To continue, uninstall setup and reboot system."
        fi
    fi

    # warn user of missing files #
    if [[ $bool_missingFiles == true ]]; then
        echo -e "Setup is not complete. Clone or re-download 'portellam/deploy-VFIO-setup' to continue."
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
