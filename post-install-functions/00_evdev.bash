#!/bin/bash sh

# function steps #
# 1. add users with UID 1000+ to groups input (evdev), libvirt (evdev and execute VMs).
# 2. parse current USB input devices and event devices.
# 3. save edits to libvirt config, restart services, exit.
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
bool_missingFiles=false

# system files #
str_outFile1="/etc/libvirt/qemu.conf"

# input files #
str_inFile1=`find . -name *etc_libvirt_qemu.conf*`

# system file backups #
str_oldFile1=$str_outFile1"_old"

# debug logfiles #
str_logFile0=`find . -name *hugepages*log*`

# prompt #
str_output1="$0: Evdev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\n\tEvdev is recommended for setups without an external KVM switch and passed-through USB controller(s).\n\tNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

echo -e $str_output1

str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1`             # find first normal user

# add to group
declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)   # find all normal users

for str_User in $arr_User; do
    sudo adduser $str_User input    # add each normal user to input group
    sudo adduser $str_User libvirt  # add each normal user to libvirt group
done  

if [[ -z $arr_InputDeviceID ]]; then
    echo -e "$0: No input devices found. Skipping."
    exit 0
else
    declare -a arr_InputDeviceID=`ls /dev/input/by-id`  # list of input devices
    declare -a arr_InputDeviceEventID=`ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0'` # list of event IDs for input devices
    
    echo -en "$0: Executing Evdev setup... "

    # /etc/libvirt/qemu.conf #
    str_output1="user = \"$str_UID1000\"\ngroup = \"user\""
    str_output2=""

    if [[ -e $str_file0 ]]; then
        str_output2="hugetlbfs_mount = \"/dev/hugepages\""
    fi
    
    str_output3="cgroup_device_acl = [\n"

    for str_InputDeviceID in $arr_InputDeviceID; do
        str_output3+="    \"/dev/input/by-id/$str_InputDeviceID\",\n"
    done

    for str_InputDeviceEventID in $arr_InputDeviceEventID; do
        str_output3+="    \"/dev/input/by-id/$str_InputDeviceEventID\",\n"
    done

    str_output3+="    \"/dev/null\", \"/dev/full\", \"/dev/zero\",\n    \"/dev/random\", \"/dev/urandom\",\n    \"/dev/ptmx\", \"/dev/kvm\",\n    \"/dev/rtc\",\"/dev/hpet\"\n]"

    if [[ -e $str_inFile1 ]]; then
        cp $str_outFile1 $str_oldFile2      # create backup
        cp $str_inFile1 $str_outFile1       # copy from template

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

            echo -e $str_line1 >> $str_outFile1
        done < $str_inFile1
    else
        bool_missingFiles=true
    fi

    # warn user of missing files #
    if [[ $bool_missingFiles == true ]]; then
        echo -e "Failed.\n$0: Files missing. Setup installation is incomplete. Clone or re-download 'portellam/VFIO-setup' to continue."
    else
        echo -e "Complete.\n"
        systemctl enable libvirtd
        systemctl restart libvirtd
    fi
fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo -e "\n$0: Review changes:\n\t'$str_file1'"
exit 0