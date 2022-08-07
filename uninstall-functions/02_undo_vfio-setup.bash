#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
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
str_inFile1=`find . -name *etc_default_grub`
str_inFile2=`find . -name *etc_modules`
str_inFile3=`find . -name *etc_initramfs-tools_modules`
str_inFile4=`find . -name *etc_modprobe.d_pci-blacklists.conf`
str_inFile5=`find . -name *etc_modprobe.d_vfio.conf`
str_inFile7=`find . -name *etc_grub.d_proxifiedScripts_custom`

if [[ -e $str_inFile1 ]]; then
    cp $str_inFile1 $str_outFile1       # copy from template
elif [[ -e $str_inFile2 ]]; then
    cp $str_inFile2 $str_outFile2       # copy from template
elif [[ -e $str_inFile3 ]]; then
    cp $str_inFile3 $str_outFile3       # copy from template
elif [[ -e $str_inFile4 ]]; then
    cp $str_inFile4 $str_outFile4       # copy from template
elif [[ -e $str_inFile5 ]]; then
    cp $str_inFile5 $str_outFile5       # copy from template
elif [[ -e $str_inFile7 ]]; then
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