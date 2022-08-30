#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#
# function steps #
# 1. add users with UID 1000+ to groups input (evdev), libvirt (evdev and execute VMs).
# 2. parse current USB input devices and event devices.
# 3. save edits to libvirt config, restart services, exit.
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $0'\n\tor\n\t'su' and 'bash $0'.\n$0: Exiting."
        exit 0
    fi

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "post-install.d" ]]; then
        if [[ -e `find . -name post-install.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name post-install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# precede with echo prompt for input #
# ask user for input then validate #
    function ReadInput {
        #echo -en "$0: "

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

# parameters #
    bool_missingFiles=false
    bool_evdev=false
    bool_lookingGlass=false
    bool_scream=false
    str_output4=""

    declare -a arr_gitRepo=(
    "duncanthrax/scream
    gnif/LookingGlass"
    )

    mkdir ./git

# system files #
    str_outFile1="/etc/libvirt/qemu.conf"
    str_outFile2="/etc/apparmor.d/abstractions/libvirt-qemu"

# input files #
    readonly str_dir1=`find .. -name files`
    if [[ -e $str_dir1 ]]; then
        cd $str_dir1
    fi

    str_inFile1=`find . -name *etc_libvirt_qemu.conf*`

# system file backups #
    str_oldFile1=$str_outFile1".old"
    str_oldFile2=$str_outFile2".old"

# debug logfiles #
    str_logFile0=`find . -name *hugepages*log*`

## prompts ##
    str_input1=""
    echo -en "$0: Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n\tSetup Evdev? [Y/n]: "
    ReadInput $str_input1

    if [[ $str_input1 == "Y"* ]]; then
        str_output4+="\n  # Evdev #\n  /dev/input/* rw,\n  /dev/input/by-id/* rw,\n"
        bool_evdev=true
    fi

    str_input1=""
    echo -en "\n$0: Looking Glass is a remote viewer of a VM GPU's primary video output, to a window on the host.\n\tNOTE: Windows VM's only!\n\tSetup Looking Glass? [Y/n]: "
    ReadInput $str_input1

    if [[ $str_input1 == "Y"* ]]; then
        str_output4+="\n  # Looking Glass #\n  /{dev,run}/shm/lookingglass rw,\n"
        touch /dev/shm/lookingglass
        chmod 666 /dev/shm/lookingglass
        bool_lookingGlass=true
    fi

    str_input1=""
    echo -en "\n$0: Scream is a virtual sound card that transmits audio through a virtual network, back to the host.\n\tSetup Scream? [Y/n]: "
    ReadInput $str_input1

    if [[ $str_input1 == "Y"* ]]; then
        str_output4+="\n  # Scream #\n  /dev/shm/scream-ivshmem rw,\n"
        touch /dev/shm/scream-ivshmem
        chmod 666 /dev/shm/scream-ivshmem
        bool_scream=true
    fi

# find first normal user #
    str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1`

# add users to groups #
    declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)

    echo
    for str_User in $arr_User; do
        sudo adduser $str_User input
        sudo adduser $str_User libvirt
    done

# list of input devices #
    declare -a arr_InputDeviceID=`ls /dev/input/by-id`  
    declare -a arr_InputDeviceEventID=`ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0'`

# /etc/libvirt/qemu.conf #
    str_output1="user = \"$str_UID1000\"\ngroup = \"user\""
    str_output2=""

# add line for hugepages, if hugepages log exists #
    if [[ -e $str_logFile0 ]]; then
        str_output2="hugetlbfs_mount = \"/dev/hugepages\""
    fi

    str_output3="cgroup_device_acl = [\n"

# add evdev #
    if [[ $bool_evdev == true ]]; then
        for str_InputDeviceID in $arr_InputDeviceID; do
            str_output3+="    \"/dev/input/by-id/$str_InputDeviceID\",\n"
        done

        for str_InputDeviceEventID in $arr_InputDeviceEventID; do
            str_output3+="    \"/dev/input/by-id/$str_InputDeviceEventID\",\n"
        done
    fi

    str_output3+="    \"/dev/null\", \"/dev/full\", \"/dev/zero\",\n    \"/dev/random\", \"/dev/urandom\",\n    \"/dev/ptmx\", \"/dev/kvm\",\n    \"/dev/rtc\",\"/dev/hpet\"\n]"

    if [[ -e $str_inFile1 ]]; then
        # backup file #
        if [[ -z $str_oldFile1 ]]; then
            cp $str_outFile1 $str_oldFile1
        else
            cp $str_oldFile1 $str_outFile1
        fi

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
    fi

# /etc/apparmor.d/abstractions/libvirt-qemu # 
    if [[ -e $str_outFile2 && $str_output4 != "" ]]; then

        # backup file #
        if [[ -z $str_oldFile2 ]]; then
            cp $str_outFile2 $str_oldFile2

        # restore from backup #
        else
            cp $str_oldFile2 $str_outFile2
        fi

        # write to file #
        echo -e "\n  # Generated by 'portellam/deploy-VFIO-setup'\n  #\n  # WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'\n  #\n  # Run 'systemctl restart apparmor.service' to update.\n"$str_output4 >> $str_outFile2
    fi

    if [[ -e $str_inFile1 && -e $str_outFile2 ]]; then
        if [[ $str_output4 != "" ]]; then
            systemctl enable libvirtd apparmor
            systemctl restart libvirtd apparmor

            # TODO: copy clients to /bin to be executed as a systemd service? user service?
            # perhaps a shortcut or even a libvirt hook?
            #
            # *** create a libvirt hook for scream and looking glass?
            #

            # parse repos #
            for str_gitRepo in $arr_gitRepo; do
                str_gitUserName=`echo $str_gitRepo | cut -d '/' -f1`

                # clone repo #
                if [[ ! `find -wholename *./git/$str_gitRepo*` ]]; then
                    mkdir ./git/$str_gitUserName
                    git clone https://www.github.com/$str_gitRepo ./git/$str_gitRepo
                fi
            done

            # install Looking Glass #
            if [[ $bool_lookingGlass == true ]]; then

                ## NOTE: not working, better to have end-user review doc's and install 'manually'

                # grab dependencies #
                str_dependencies="binutils-dev cmake fonts-dejavu-core libfontconfig-dev gcc g++ pkg-config libegl-dev libgl-dev libgles-dev libspice-protocol-dev nettle-dev libx11-dev libxcursor-dev libxi-dev libxinerama-dev libxpresent-dev libxss-dev libxkbcommon-dev libwayland-dev wayland-protocols"
                #sudo apt update && sudo apt full-upgrade -y && sudo apt install -y $str_dependencies

                if [[ ! -z "./git/gnif/LookingGlass/" ]]; then
                    #mkdir ./git/gnif/LookingGlass/client/build
                    #cd ./git/gnif/LookingGlass/client/build
                    #cmake ../
                    #make
                    #echo -e "\n$0: Installed Looking Glass client.\n\tReview documentation to install server and complete setup ('https://looking-glass.io')."
                    echo -e "\n$0: Review documentation to install Looking Glass and complete setup ('https://looking-glass.io')."
                else
                    echo -e "\n$0: Missing 'gnif/LookingGlass'."
                fi
            fi

            # install Scream #
            if [[ $bool_scream == true ]]; then

                ## NOTE: not working, better to have end-user review doc's and install 'manually'

                # grab dependencies #
                str_dependencies="libpulse-dev"
                #apt update && apt full-upgrade -y && apt install -y $str_dependencies

                if [[ ! -z "./git/gnif/LookingGlass/" ]]; then
                    #mkdir ./git/duncanthrax/scream/build
                    #cd ./git/duncanthrax/scream/build
                    #cmake ..
                    #make
                    #echo -e "\n$0: Installed Scream client.\n\tReview documentation to install server and complete setup ('https://github.com/duncanthrax/scream/')."
                    echo -e "\n$0: Review documentation to install Scream and complete setup ('https://github.com/duncanthrax/scream/')."
                else
                    echo -e "\n$0: Missing 'duncanthrax/scream'."
                fi
            fi

            echo -e "\n$0: Review changes:\n\t'$str_outFile1'\n\t'$str_outFile2'"
        fi
    else
        echo -e "Failed. File(s) missing:"

        if [[ -z $str_inFile1 ]]; then 
            echo -e "\t'$str_inFile1'"
        fi

        if [[ -z $str_outFile2 ]]; then 
            echo -e "\t'$str_outFile2'"
        fi
    fi

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0