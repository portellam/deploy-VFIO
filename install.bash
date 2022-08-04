#!/bin/bash sh

# TODO
# -install required packages for VFIO, and new features
# -packages for major distros (Debian,Fedora,Arch)
# -setup audio loopback for systems with soundcard passthrough (line-out to host line-in)

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

## user input ##
str_output1=""

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

# check if system supports IOMMU #
if [[ -z $(echo `compgen -G "/sys/kernel/iommu_groups/*/devices/*"`) ]]; then

    echo "$0: WARNING: Virtualization (AMD IOMMU or Intel VT-D) is NOT enabled or available in the BIOS/UEFI.\n$0: VFIO setup will continue, enable/review availability after execution."

else

    echo "$0: NOTE: Virtualization is enabled in the BIOS/UEFI."

fi

## install required packages ##

# Arch
if [[ `lsb_release -i | grep -Ei "arch"` ]]; then

    echo -e "$0: Linux distribution found: `cat /etc/*-release | grep ID | sort -h | head -n1 | cut -d '=' -f2`\n"
    sudo pacman -Syu && sudo pacman -Sy edk2-ovmf lgit ibvirt qemu-desktop virt-manager zramswap
    # NOTE: find same packages from Debian

fi

# Debian/Ubuntu
if [[ `lsb_release -i | grep -Ei "debian|ubuntu"` ]]; then

    echo -e "$0: Linux distribution found: `cat /etc/*-release | grep ID | sort -h | head -n1 | cut -d '=' -f2`\n"
    sudo apt update && sudo apt full-upgrade -y && sudo apt install -y git libvirt0 qemu virt-manager zram-tools

fi

# Fedora/Redhat
if [[ `lsb_release -i | grep -Ei "fedora|redhat"` ]]; then

    echo -e "$0: Linux distribution found: `cat /etc/*-release | grep ID | sort -h | head -n1 | cut -d '=' -f2`\n"
    sudo dnf check-update && sudo dnf upgrade -y && sudo dnf install -y @virtualization git zram-generator zram-generator-defaults
    # NOTE: find same packages from Debian    # is there a virtualization metapackage for Debian, Arch?

fi

echo

# parse and execute functions #
echo -e "$0: Executing functions..."
str_dir1="install-functions"
declare -a arr_dir1=`ls $str_dir1 | sort -h`

# call functions #
for str_line1 in $arr_dir1; do

    # input variable auto executes functions #
    if [[ `echo $1 | tr '[:lower:]' '[:upper:]'` == "Y"* ]]; then
        str_input1="Y"
    else
        str_input1=""
    fi
    
    str_output1="Execute '$str_line1'? [Y/n]: "

    # execute sh/bash scripts in directory
    if [[ $str_line1 == *".bash"||*".sh" && $str_line1 != *".log" ]]; then
        ReadInput $str_input1
        echo
    fi

    if [[ $str_input1 == "Y" && $str_line1 == *".bash" && $str_line1 != *".log" ]]; then
        sudo bash $str_dir1"/"$str_line1
    fi

    if [[ $str_input1 == "Y" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
        sudo sh $str_dir1"/"$str_line1
    fi
done

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo -e "$0: Reboot system for changes to take effect. Exiting."
exit 0