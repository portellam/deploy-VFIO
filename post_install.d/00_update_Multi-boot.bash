#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
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

    if [[ `echo ${str_pwd##*/}` != "post_install.d" ]]; then
        if [[ -e `find .. -name post_install.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find .. -name post_install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

echo -en "$0: Updating Multi-boot setup... "

## parameters ##
    readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
    declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3`)     # first three kernels
    # str_rootKernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`                   # latest kernel
    # readonly str_rootKernel=${str_rootKernel: 1}
    readonly str_rootDisk=`df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1`
    readonly str_rootUUID=`blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2`
    str_rootFSTYPE=`blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2`

    if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then
        readonly str_rootFSTYPE="ext2"
    fi

# input files #
    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

    readonly str_inFile1=`find . -name *etc_grub.d_proxifiedScripts_custom`
    readonly str_inFile1b=`find . -name *Multi-boot_template`
    readonly str_logFile1=`find .. -name *VFIO_setup*log*`

# system files #
    readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"

# system file backups #
    readonly str_oldFile1=$str_outFile1".old"

cp $str_inFile1 $str_outFile1          # copy over blank

## /etc/grub.d/proxifiedScripts/custom ##

    # parse log file #
    while read -r str_line1; do

        # new parameters #
        int_IOMMU_VFIO_VGA=`echo $str_line1 | cut -d '#' -f2 | cut -d ' ' -f1`
        str_thisFullName=`echo $str_line1 | cut -d '#' -f3`
        str_GRUB_CMDLINE=`echo $str_line1 | cut -d '#' -f4`

        # update parameters #
        if [[ ${str_thisFullName: -1} == " " ]]; then
            str_thisFullName=${str_thisFullName::-1}
        fi

        # debug prompt #
        # echo
        # echo -e "$0: '$""int_IOMMU_VFIO_VGA'\t\t= $int_IOMMU_VFIO_VGA"
        # echo -e "$0: '$""str_thisFullName'\t\t= $str_thisFullName"
        # echo -e "$0: '$""str_GRUB_CMDLINE'\t\t= $str_GRUB_CMDLINE"

        # parse kernels #
        for (( int_i=0 ; int_i<${#arr_rootKernel[@]} ; int_i++)); do

            # match #
            if [[ -e ${arr_rootKernel[$int_i]} || ${arr_rootKernel[$int_i]} != "" ]]; then
                str_thisRootKernel=${arr_rootKernel[$int_i]:1}

                # new parameters #
                str_output1='menuentry "'"`lsb_release -i -s` `uname -o`, with `uname` $str_thisRootKernel (VFIO, w/o IOMMU '$int_IOMMU_VFIO_VGA', w/ boot VGA '$str_thisFullName')\" {"
                str_output2="\tinsmod $str_rootFSTYPE"
                str_output3="\tset root='/dev/disk/by-uuid/$str_rootUUID'"
                str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"$str_rootUUID\n\t"'fi'
                str_output5="\techo    'Loading Linux $str_thisRootKernel ...'"
                str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                str_output7="\tinitrd  /boot/initrd.img-$str_thisRootKernel"

                # debug prompt #
                # echo -e "$0: '$""str_output2'\t\t= $str_output2"
                # echo -e "$0: '$""str_output3'\t\t= $str_output3"
                # echo -e "$0: '$""str_output4'\t\t= $str_output4"
                # echo -e "$0: '$""str_output5'\t\t= $str_output5"
                # echo -e "$0: '$""str_output6'\t\t= $str_output6"
                # echo -e "$0: '$""str_output7'\t\t= $str_output7"
                # echo

                if [[ -e $str_inFile1b && -e $str_logFile1 ]]; then
                    # if [[ -e $str_outFile1 ]]; then
                    #     mv $str_outFile1 $str_oldFile1  # create backup
                    # fi

                    # write to tempfile #
                    echo -e >> $str_outFile1

                    while read -r str_line2; do
                        case $str_line2 in

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
                                str_outLine1="$str_line2";;
                        esac

                        # write to system file #
                        echo -e "$str_outLine1" >> $str_outFile1
                    done < $str_inFile1b                # read from template
                else
                    bool_missingFiles=true
                fi
            fi
        done
    done < $str_logFile1                                # read from log file

    if [[ $bool_missingFiles == true ]]; then
        echo -e "Failed.\n$0: File(s) missing:"

        if [[ -z $str_logFile1b ]]; then
            echo -e "\t'$str_logFile1b'"
        fi
    else
        chmod 755 $str_outFile1 $str_oldFile1b          # set proper permissions
        echo -e "Complete."
        sudo update-grub
    fi

exit 0
