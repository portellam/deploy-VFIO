#!/bin/bash sh

# TO-DO:
# -merge libvirt-nosleep with invoke hooks
# -redo with hooks and make an updater script that copies hooks to individual domain/vm folders
# -create sym link to each VM from template hook scripts

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

    if [[ `echo ${str_pwd##*/}` != "post-install.d" ]]; then
        if [[ -e `find . -name post-install.d` ]]; then
            # echo -e "Script located the correct working directory."
            cd `find . -name post-install.d`
        else
            echo -e "WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "Script is in the correct working directory."
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

echo -en "Executing... "

# parameters #
    str_outDir1="/etc/libvirt/hooks/"
    str_inDir1=`find .. -name *libvirt_hooks*`
    arr_domains=( `ls /etc/libvirt/qemu | grep -iv 'networks' | sort -h | grep '.xml'` )

#
    if [[ -e $str_inDir1"/qemu" ]]; then
        cp $str_inDir1"/qemu" $str_outDir1"/qemu"

    #if [[ -e $str_inDir1"/*" ]]; then
        #cp -r $str_inDir1/* $str_outDir1

        #if [[ ${#arr_domains[@]} -gt 0 ]]; then
            #for str_element in ${arr_domains[@]}; do
                # NOTE: do something here 
            #done
        #fi
        echo -e "Complete."
    else
        echo -e "Failed. File(s) missing:"
        echo -e "\t$str_inDir1"
        ls -al $str_inDir1
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0