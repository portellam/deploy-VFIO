#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\nExiting."
        exit 0
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=""
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!
            else
                echo -en "$str_output1"
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

    if [[ `echo ${str_pwd##*/}` != "post_install.d" ]]; then
        if [[ -e `find .. -name post_install.d` ]]; then
            # echo -e "Script located the correct working directory."
            cd `find .. -name post_install.d`
        else
            echo -e "WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "Script is in the correct working directory."
    fi

echo -e "Updating Multi-boot setup..."

## parameters ##
    declare -a arr_GRUBmenuEntry=()
    declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3`)     # first three kernels
    readonly str_rootDisk=`df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1`
    readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
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
    readonly str_logFile1=`find . -name *VFIO_setup*log*`

# system files #
    readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"
    readonly str_outFile2="/etc/default/grub"

# system file backups #
    readonly str_oldFile1=$str_outFile1".old"
    readonly str_oldFile2=$str_outFile2".old"

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
        # echo -e "'$""int_IOMMU_VFIO_VGA'\t\t= $int_IOMMU_VFIO_VGA"
        # echo -e "'$""str_thisFullName'\t\t= $str_thisFullName"
        # echo -e "'$""str_GRUB_CMDLINE'\t\t= $str_GRUB_CMDLINE"

        # parse kernels #
        for (( int_i=0 ; int_i<${#arr_rootKernel[@]} ; int_i++)); do

            # match #
            if [[ -e ${arr_rootKernel[$int_i]} || ${arr_rootKernel[$int_i]} != "" ]]; then
                str_thisRootKernel=${arr_rootKernel[$int_i]:1}

                # new parameters #
                str_thisGRUBmenuEntry="`lsb_release -i -s` `uname -o`, with `uname` $str_thisRootKernel (VFIO, w/o IOMMU '$int_IOMMU_VFIO_VGA', w/ boot VGA '$str_thisFullName')"
                str_output1="menuentry \"$str_thisGRUBmenuEntry\" {"
                str_output2="\tinsmod $str_rootFSTYPE"
                str_output3="\tset root='/dev/disk/by-uuid/$str_rootUUID'"
                str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"$str_rootUUID\n\t"'fi'
                str_output5="\techo    'Loading Linux $str_thisRootKernel ...'"
                str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                str_output7="\tinitrd  /boot/initrd.img-$str_thisRootKernel"

                # debug prompt #
                # echo -e "'$""str_output2'\t\t= $str_output2"
                # echo -e "'$""str_output3'\t\t= $str_output3"
                # echo -e "'$""str_output4'\t\t= $str_output4"
                # echo -e "'$""str_output5'\t\t= $str_output5"
                # echo -e "'$""str_output6'\t\t= $str_output6"
                # echo -e "'$""str_output7'\t\t= $str_output7"
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

                arr_GRUBmenuEntry+=(`echo $str_thisGRUBmenuEntry`)
            fi
        done
    done < $str_logFile1                                # read from log file

    if [[ $bool_missingFiles == true ]]; then
        echo -e "Updating Multi-boot setup... Failed.\n File(s) missing:"

        if [[ -z $str_logFile1 ]]; then
            echo -e "\t'$str_logFile1'"
        fi
    else
        chmod 755 $str_outFile1 $str_oldFile1b          # set proper permissions

        # parameters #
        bool_loop=true
        readonly str_currentKernel=`uname -r`

        # write to system file #
        if [[ ${#arr_GRUBmenuEntry[@]} -gt 0 ]]; then
            while [[ $bool_loop == true ]]; do
                for str_thisGRUBmenuEntry in ${arr_GRUBmenuEntry[@]}; do

                    if [[ $str_thisGRUBmenuEntry == *"$str_currentKernel"* ]]; then                   # uncomment to parse current kernel with a menu entry
                    # if true; then                                                                     # uncomment to parse every kernel with a menu entry

                        # parameters #
                        str_output1="\n\nSet the given GRUB menu entry as default:\n\t\"$str_thisGRUBmenuEntry\"\n\t[Y/n]: "

                        ReadInput $str_output1

                        case $str_input1 in
                            "Y")
                                bool_loop=false
                                break;;

                            "N")
                                str_output2="Skipped GRUB menu entry."
                                str_thisGRUBmenuEntry=""                # clear field
                                bool_loop=false;;

                            *)
                                ;;
                        esac

                        echo -en "$str_output2 "

                    else
                        str_thisGRUBmenuEntry=""                # clear field
                    fi
                done

                if [[ $str_thisGRUBmenuEntry == "" ]]; then
                    echo -e "No selection. Skipping."
                fi

                # parameters #
                bool_foundLineMatch=false
                bool_foundCommentLineMatch=false

                # write to GRUB #
                if [[ -e $str_outFile2 ]]; then

                    # clear logfile #
                    if [[ -e $str_oldFile2 ]]; then
                        rm $str_oldFile2
                    fi

                    touch $str_oldFile2

                    # parse system file #
                    while read -r str_line2; do

                        # match line #
                        if [[ $bool_foundLineMatch == false && $str_line2 == *"GRUB_DEFAULT="* ]]; then

                            # match exact line #
                            if [[ $str_line2 != "#"* ]]; then
                                str_line2="GRUB_DEFAULT=\"$str_thisGRUBmenuEntry\""
                                bool_foundLineMatch=true

                            # match commented line #
                            else
                                bool_foundCommentLineMatch=true
                            fi
                        fi

                        echo -e $str_line2 >> $str_oldFile2
                    done < $str_outFile2        # read from template

                    # should loop find no line match, append the selection to the end of the file #
                    if [[ $bool_foundCommentLineMatch == true && $bool_foundLineMatch == false ]]; then
                        str_line2="GRUB_DEFAULT=\"$str_thisGRUBmenuEntry\""
                        echo -e $str_line2 >> $str_oldFile2
                    fi

                    # copy over system file #
                    if [[ -e $str_oldFile2 ]]; then
                        cp $str_oldFile2 $str_outFile2
                        str_output2="Set GRUB menu entry as default."
                    else
                        str_output2="Write failed. File(s) missing:\t'$str_oldFile2'"
                    fi
                else
                    str_output2="Write failed. File(s) missing:\t'$str_outFile2'"
                fi

                echo
                break
            done
        fi

        echo
    fi

    echo -e "Updating Multi-boot setup... Complete."
    sudo update-grub

exit 0
