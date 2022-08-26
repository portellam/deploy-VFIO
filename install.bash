#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

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
        echo "$0: Virtualization is enabled in the BIOS/UEFI."
    fi

## install required packages ##
    function CheckDistro
    {

        echo -e "$0: Linux distribution found: `lsb_release -i -s`\n$0: Checking for updates...\n"

        # Arch
        if [[ `lsb_release -i -s | grep -Ei "arch"` ]]; then
            sudo pacman -Syu && sudo pacman -Sy edk2-ovmf lgit ibvirt qemu-desktop virt-manager zramswap
            # NOTE: find same packages from Debian

        # Debian/Ubuntu
        elif [[ `lsb_release -i -s | grep -Ei "debian|ubuntu"` ]]; then
            sudo apt update && sudo apt full-upgrade -y && sudo apt install -y git libvirt0 qemu virt-manager zram-tools

        # Fedora/Redhat
        elif [[ `lsb_release -i -s | grep -Ei "fedora|redhat"` ]]; then
            sudo dnf check-update && sudo dnf upgrade -y && sudo dnf install -y @virtualization git zram-generator zram-generator-defaults
            # NOTE: find same packages from Debian    # is there a virtualization metapackage for Debian, Arch?

        else
            echo -e "Checking for updates... Failed.\n$0: Linux distibution is not recognized for or compatible with 'deploy-VFIO-setup'."
            str_output1="Continue? [Y/n]: "
            ReadInput $str_input1

            if [[ $str_input1 == "Y" ]]; then
                echo -e "$0: Continuing."
            fi

            if [[ $str_input1 == "N" ]]; then
                echo -e "$0: Exiting."
                IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0
            fi

            # NOTE: test!
        fi

        echo
    }

    # CheckDistro       # call function

# parse and execute functions #
    str_output1=""
    str_dir1="install.d"

    if [[ -z `find . -name $str_dir1*` ]]; then
        echo -e "$0: Executing functions... Failed. Missing files."
    else
        echo -e "$0: Executing functions...\n"

        declare -a arr_dir1=`ls $str_dir1 | sort -h`
        # call functions #
        for str_line1 in $arr_dir1; do

            # input variable auto executes functions #
            if [[ `echo $1 | tr '[:lower:]' '[:upper:]'` == "Y"* ]]; then
                str_input1="Y"
            else
                str_input1=""
            fi

            # execute sh/bash scripts in directory
            if [[ $str_line1 == *".bash"||*".sh" && $str_line1 != *".log" ]]; then
                str_output1="Execute '$str_line1'? [Y/n]: "
                ReadInput $str_input1
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".bash" && $str_line1 != *".log" ]]; then
                sudo bash $str_dir1"/"$str_line1
            fi

            if [[ $str_input1 == "Y" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
                sudo sh $str_dir1"/"$str_line1
            fi

            echo
        done

        echo -e "$0: Review changes made. Exiting."
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0