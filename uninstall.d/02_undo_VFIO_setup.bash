#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_file1=$(echo ${0##/*})
            str_file1=$(echo $str_file1 | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'. Exiting."
            exit 1
        fi
    }

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "uninstall.d" ]]; then
        if [[ -e `find . -name uninstall.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name uninstall.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# prompt #
    echo -en "$0: Uninstalling VFIO setup... "

# system files #
    str_outFile1="/etc/default/grub"
    str_outFile2="/etc/modules"
    str_outFile3="/etc/initramfs-tools/modules"
    str_outFile4="/etc/modprobe.d/pci-blacklists.conf"
    str_outFile5="/etc/modprobe.d/vfio.conf"
    str_outFile7="/etc/grub.d/proxifiedScripts/custom"

# input files #
    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

    str_inFile1=`find . -name *etc_default_grub`
    str_inFile2=`find . -name *etc_modules`
    str_inFile3=`find . -name *etc_initramfs-tools_modules`
    str_inFile4=`find . -name *etc_modprobe.d_pci-blacklists.conf`
    str_inFile5=`find . -name *etc_modprobe.d_vfio.conf`
    str_inFile7=`find . -name *etc_grub.d_proxifiedScripts_custom`

# output files #
    str_output1="GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo "`lsb_release -i -s`"\`"
    str_output2="GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\""

# write to files #
    if [[ -e $str_inFile1 ]]; then
        if [[ -e $str_outFile1 ]]; then
            rm $str_outFile1
        fi

        while read -r str_line1; do
            if [[ $str_line1 == '#$str_output1'* ]]; then
                str_line1=$str_output1
            fi

            if [[ $str_line1 == '#$str_output2'* ]]; then
                str_line1=$str_output2
            fi

            echo $str_line1 >> $str_outFile1
        done < $str_inFile1
    else
        bool_missingFiles=true
    fi

    if [[ -e $str_inFile2 ]]; then
        cp $str_inFile2 $str_outFile2       # copy from template
    else
        bool_missingFiles=true
    fi

    if [[ -e $str_inFile3 ]]; then
        cp $str_inFile3 $str_outFile3       # copy from template
    else
        bool_missingFiles=true
    fi

    if [[ -e $str_inFile4 ]]; then
        cp $str_inFile4 $str_outFile4       # copy from template
    else
        bool_missingFiles=true
    fi

    if [[ -e $str_inFile5 ]]; then
        cp $str_inFile5 $str_outFile5       # copy from template
    else
        bool_missingFiles=true
    fi

    if [[ -e $str_inFile7 ]]; then
        cp $str_inFile7 $str_outFile7       # copy from template
    else
        bool_missingFiles=true
    fi

    if [[ $bool_missingFiles == true ]]; then
        echo -e "Failed. File(s) missing:"

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

        if [[ -z $str_inFile7 ]]; then
            echo -e "\t'$str_inFile7'"
        fi

    else
        echo -e "Complete.\n"
        sudo update-grub                    # update GRUB
        sudo update-initramfs -u -k all     # update INITRAMFS
    fi

echo
IFS=$SAVEIFS                        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0
