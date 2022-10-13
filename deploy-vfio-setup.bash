#!/bin/bash sh

##
## Author(s):    Alex Portell <github.com/portellam>
##


##
## TO-DO:
##  -organize error codes
##  -reduce redundant code
##  -separate concerns: for example, error code exits (pass or fail), and error code exceptions (specific details). Call these funcs separately.
##

## prep and I/O functions ##
    function CheckIfUserIsRoot
    {
        if [[ $( whoami ) != "root" ]]; then
            str_thisFile=$( echo ${0##/*} )
            str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
            echo -e "\e[33mWARNING:\e[0m"" Script must execute as root. In terminal, run:\n\t'sudo bash $str_thisFile'"
            ExitWithThisExitCode
        fi
    }

    function CheckIfFileOrDirExists
    {
        false
        echo -en "Checking if file or directory exists... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # dir/file not found
        if [[ ! -e $1 ]]; then
            find . -name $1 | uniq &> /dev/null || (exit 255)
        fi

        case "$?" in
            0)
                echo -e "\e[32mSuccessful.\e[0m"
                true;;

            255)
                echo -e "\e[31mFailed.\e[0m"" Could not find '$1'.";;

            254)
                echo -e "\e[31mFailed.\e[0m"" Null exception/invalid input.";;
        esac
    }

    function CreateBackupFromFile
    {
        # behavior:
        #   create a backup file
        #   return boolean, to be used by main
        #

        false
        echo -en "Backing up file... "

        # parameters #
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions
        # null exception
        if [[ -z $str_thisFile ]]; then
            (exit 254)
        fi

        # file not found exception
        if [[ ! -e $str_thisFile ]]; then
            (exit 250)
        fi

        # file not readable exception
        if [[ ! -r $str_thisFile ]]; then
            (exit 249)
        fi

        # work #
        if [[ "$?" -eq 0 ]]; then

            # parameters #
            declare -r str_suffix=".old"
            declare -r str_thisDir=$( dirname $1 )
            declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

            # positive non-zero count
            if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then

                # parameters #
                declare -ir int_maxCount=5
                str_line=${arr_thisDir[0]}
                str_line=${str_line%"${str_suffix}"}        # substitution
                str_line=${str_line##*.}                    # ditto

                # check if string is a valid integer #
                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                    declare -ir int_firstIndex="${str_line}"

                else
                    (exit 254)
                fi

                for str_element in ${arr_thisDir[@]}; do
                    if cmp -s $str_thisFile $str_element; then
                        (exit 3)
                        break
                    fi
                done

                # if latest backup is same as original file, exit
                if cmp -s $str_thisFile ${arr_thisDir[-1]}; then
                    (exit 3)
                fi

                # before backup, delete all but some number of backup files
                while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do
                    if [[ -e ${arr_thisDir[0]} ]]; then
                        rm ${arr_thisDir[0]}
                        break
                    fi
                done

                # if *first* backup is same as original file, exit
                if cmp -s $str_thisFile ${arr_thisDir[0]}; then
                    (exit 3)
                fi

                # new parameters #
                str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
                str_line=${str_line##*.}                        # ditto

                # check if string is a valid integer #
                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                    declare -i int_lastIndex="${str_line}"

                else
                    (exit 254)
                fi

                (( int_lastIndex++ ))           # counter

                # source file is newer and different than backup, add to backups
                if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                    cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"

                elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                    (exit 3)

                else
                    (exit 3)
                fi

            # no backups, create backup
            else
                cp $str_thisFile "${str_thisFile}.0${str_suffix}"
            fi
        fi

        # append output and return code
        case "$?" in
            0)
                echo -e "\e[32mSuccessful.\e[0m"
                true;;

            3)
                echo -e "\e[33mSkipped.\e[0m"" No changes from most recent backup."
                true;;

            255)
                echo -e "\e[31mFailed.\e[0m""";;

            254)
                echo -e "\e[31mFailed.\e[0m"" Exception: Null/invalid input.";;

            253)
                echo -e "\e[31mFailed.\e[0m"" Exception: File '$str_thisFile' does not exist.";;

            252)
                echo -e "\e[31mFailed.\e[0m"" Exception: File '$str_thisFile' is not readable.";;
        esac
    }

    function CreateFile
    {
        false
        echo -en "Creating file... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            touch $1 &> /dev/null || (exit 247)

        else
            (exit 3)
        fi

        case "$?" in
            3)
                echo -e "File '$1' exists."
                true;;
        esac
    }

    function DeleteFile
    {
        echo -en "Deleting file... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            (exit 3)

        else
            rm $1 &> /dev/null || (exit 255)
        fi

        case "$?" in
            0)
                echo -e "\e[32mSuccessful.\e[0m"
                true;;

            3)
                PassOrFailThisExitCode
                echo -e "\e[33mSkipped.\e[0m"" File '$1' does not exist."
                true;;

            255)
                echo -e "\e[31mFailed.\e[0m"" Could not delete file '$1'.";;

            254)
                echo -e "\e[31mFailed.\e[0m"" Null exception/invalid input.";;
        esac
    }

    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $?
    }

    function PassOrFailThisExitCode
    {
        # output a pass or fail depending on the exit code

        #
        # reserved/unreserved exit codes #
        #
        #   0       == always pass
        #   3       == free
        #   131-255 == free
        #

        if [[ ! -z $1 ]]; then
            echo -en "$1"
        fi

        # append output #
        case "$?" in
            0||3)
                echo -e " [32mSuccessful. \e[0m";;

            *)
                echo -e " [31mFailed. \e[0m";;
        esac
    }

    function ParseThisExitCode
    {
        # output a specific error/exception given exit code

        #
        # relative exit codes
        #
        #   3       == pass with some errors
        #   255-248 == specified
        #   <= 247  == function specific
        #

        if [[ ! -z $1 ]]; then
            echo -en "$1"
        fi

        # append output #
        case "$?" in
            255)
                echo;;      # unspecified error

            254)
                echo -e "Exception: Null input.";;

            253)
                echo -e "Exception: Invalid input.";;

            252)
                echo -e "Error: Missed steps; missed execution of key subfunctions.";;

            251)
                echo -e "Error: Missing components/variables.";;

            250)
                echo -e "Exception: File does not exist.";;

            249)
                echo -e "Exception: File is not readable.";;

            248)
                echo -e "Exception: File is not writable.";;

            *)
                echo;;
        esac

        echo
    }

    function ReadInput
    {
        # behavior:
        #
        # ask for Yes/No answer, return boolean,
        # default selection is N/false
        # always returns bool
        #

        false

        # using statements #
        shopt -s nocasematch

        # parameters #
        declare -lir int_maxCount=3
        declare -lar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 [Y/n]: "
            read str_input1

            case $str_input1 in
                "Y")
                    echo
                    break;;

                "N")
                    echo
                    break;;

                *)
                    if [[ $int_element -eq $int_maxCount ]]; then
                        echo -e "Exceeded max attempts.\n"
                        str_input1="N"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m ";;
            esac
        done

        case $str_input1 in
            "Y")
                true;;

            "N")
                false;;
        esac
    }

    function ReadInputFromMultipleChoiceIgnoreCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            echo -e "\e[31mFailed.\e[0m"" Exception: Null/invalid input."
            false

        else

            # parameters #
            declare -lir int_maxCount=3
            declare -lar arr_count=$( seq $int_maxCount )

            # using statements #
            shopt -s nocasematch

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1

                if [[ -z $2 && $str_input1 == $2 ]]; then
                    break

                elif [[ -z $3 && $str_input1 == $3 ]]; then
                    break

                elif [[ -z $4 && $str_input1 == $4 ]]; then
                    break

                elif [[ -z $5 && $str_input1 == $5 ]]; then
                    break

                elif [[ -z $6 && $str_input1 == $6 ]]; then
                    break

                elif [[ -z $7 && $str_input1 == $7 ]]; then
                    break

                elif [[ -z $8 && $str_input1 == $8 ]]; then
                    break

                elif [[ -z $9 && $str_input1 == $9 ]]; then
                    break

                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        echo -e "Exceeded max attempts."
                        str_input1=$2                       # default selection: first choice
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                fi
            done
        fi

        echo
    }

    function ReadInputFromMultipleChoiceUpperCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            echo -e "\e[31mFailed.\e[0m"" Exception: Null/invalid input."
            false

        else

            # parameters #
            declare -lir int_maxCount=3
            declare -lar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ ! -z $2 && $str_input1 == $2 ]]; then
                    break

                elif [[ ! -z $3 && $str_input1 == $3 ]]; then
                    break

                elif [[ ! -z $4 && $str_input1 == $4 ]]; then
                    break

                elif [[ ! -z $5 && $str_input1 == $5 ]]; then
                    break

                elif [[ ! -z $6 && $str_input1 == $6 ]]; then
                    break

                elif [[ ! -z $7 && $str_input1 == $7 ]]; then
                    break

                elif [[ ! -z $8 && $str_input1 == $8 ]]; then
                    break

                elif [[ ! -z $9 && $str_input1 == $9 ]]; then
                    break

                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        echo -e "Exceeded max attempts."
                        str_input1=$2                       # default selection: first choice
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                fi
            done
        fi

        echo
    }

    function ReadInputFromRangeOfNums
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        # parameters #
        declare -lir int_maxCount=3
        declare -lar arr_count=$( seq $int_maxCount )

        # using statements #
        shopt -s nocasematch

        for int_element in ${arr_count[@]}; do
            echo -en "$1 "
            read str_input1

            # valid input #
            if [[ $str_input1 -ge $2 && $str_input1 -le $3 ]]; then
                break
            fi

            # default input #
            if [[ $int_element -eq $int_maxCount ]]; then
                echo -e "Exceeded max attempts."
                str_input1=$2                       # default selection: first choice
                break
            fi

            # check if string is a valid integer #
            if [[ ! ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null; then
                echo -en "\e[33mInvalid input.\e[0m "
            fi
        done

        echo
    }

    function TestNetwork
    {
        # behavior:
        #   test internet connection and DNS servers
        #   return boolean, to be used by main
        #

        # test IP resolution
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) && echo -e "\e[32mSuccessful.\e[0m" || ( echo -e "\e[31mFailed.\e[0m""" && (exit 255) )          # set exit status, but still execute rest of function

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) && echo -e "\e[32mSuccessful.\e[0m" || ( echo -e "\e[31mFailed.\e[0m""" && (exit 255) )   # ditto

        if [[ "$?" -ne 0 ]]; then
                echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    function WriteVarToFile
    {
        # behavior:
        #
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        # NOTE: necessary for newline preservation in arrays and files #
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "

        # null exception
        if [[ -z $1 || -z $2 ]]; then
            (exit 254)
        fi

        # file not found exception
        if [[ ! -e $1 ]]; then
            (exit 253)
        fi

        # file not readable exception
        if [[ ! -r $1 ]]; then
            (exit 252)
        fi

        # file not readable exception
        if [[ ! -w $1 ]]; then
            (exit 251)
        fi

        if [[ "$?" -eq 0 ]]; then
            echo $2 >> $1 || (exit 255)
        fi

        PassOrFailThisExitCode
    }
##

## context functions ##
    function CheckIfIOMMU_IsEnabled
    {
        echo -en "Checking if Virtualization is enabled/supported... "

        if [[ -z $(compgen -G "/sys/kernel/iommu_groups/*/devices/*") ]]; then
            echo -e "\e[31mFailed.\e[0m"""
            ExitWithThisExitCode

        else
            echo -e "\e[32mSuccessful.\e[0m"
            true
        fi

        echo
    }

    function CloneOrUpdateGitRepositories
    {
        true
        echo -en "Cloning Git repositories... "

        # dir #
            # null exception
            if [[ -z $1 || -z $2 ]]; then
                (exit 254)
            fi

            # dir not found exception
            if [[ ! -d $1 ]]; then
                (exit 253)
            fi

            # dir not writeable exception
            if [[ ! -w $1 ]]; then
                (exit 252)
            fi

            case "$?" in
                0)
                    cd $1
                    true;;

                255)
                    echo -e "\e[31mFailed.\e[0m""";;

                254)
                    echo -e "\e[31mFailed.\e[0m"" Null exception/invalid input.";;

                253)
                    echo -e "\e[31mFailed.\e[0m"" Dir '$1' does not exist.";;

                252)
                    echo -e "\e[31mFailed.\e[0m"" Dir '$1' is not writeable.";;
            esac

            if [[ $? -ge 131 ]]; then
                exit
            fi

        # git repos #
            false

            # null exception
            if [[ -z $1 || -z $2 ]]; then
                (exit 254)
            fi

            # dir not found exception
            if [[ ! -d $1 ]]; then
                (exit 253)
            fi

            # dir not writeable exception
            if [[ ! -w $1 ]]; then
                (exit 252)
            fi

        # if a given element is a string longer than one char, the var is an array #
        for str_element in ${2}; do
            if [[ ${#str_element} -gt 1 ]]; then
                bool_varIsAnArray=true
                break
            fi
        done

        declare -i int_count=1

        if [[ "$?" -eq 0 ]]; then

            # git clone from array #
            if [[ $bool_varIsAnArray == true ]]; then
                for str_element in ${2}; do

                    # cd into repo, update, and back out
                    if [[ -e $( basename $1 ) ]]; then
                        cd $( basename $1 )
                        git pull $str_element &> /dev/null || ( ((int_count++)) && (exit 3) )
                        cd ..

                    # clone new repo
                    else
                        git clone $str_element &> /dev/null || ( ((int_count++)) && (exit 3) )
                    fi

                done

                # if all repos failed to clone, change exit code
                if [[ ${#2[@]} -eq $int_count ]]; then
                    (exit 255)
                fi

            # git clone a repo #
            else
                echo $2 >> $1 || (exit 255)
            fi

        fi

        case "$?" in
            0)
                echo -e "\e[32mSuccessful.\e[0m"
                true;;

            3)
                echo -e "\e[32mSuccessful.\e[0m One or more Git repositories could not be cloned.";;

            255)
                echo -e "\e[31mFailed.\e[0m""";;

            254)
                echo -e "\e[31mFailed.\e[0m"" Null exception/invalid input.";;
        esac

        echo
    }

    function ParseIOMMUandPCI
    {
        false
        echo -en "Parsing IOMMU groups... "

        # parameters #
        declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
        declare -a arr_DeviceIOMMU=()
        declare -a arr_DevicePCI_ID=()
        declare -a arr_DeviceDriver=()
        declare -a arr_DeviceName=()
        declare -a arr_DeviceType=()
        declare -a arr_DeviceVendor=()
        bool_missingDriver=false
        bool_foundVFIO=false

        # parse list of IOMMU groups #
        for str_element1 in $( find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V ); do

            # parameters #
            str_thisIOMMU=$( basename $str_element1 )

            # parse given IOMMU group for PCI IDs #
            for str_element2 in $( ls ${str_element1}/devices ); do

                # parameters #
                # save output of given device #
                str_thisDevicePCI_ID="${str_element2##"0000:"}"
                str_thisDeviceName="$( lspci -ms ${str_element2} | cut -d '"' -f6 )"
                str_thisDeviceType="$( lspci -ms ${str_element2} | cut -d '"' -f2 )"
                str_thisDeviceVendor="$( lspci -ms ${str_element2} | cut -d '"' -f4 )"
                str_thisDeviceDriver="$( lspci -ks ${str_element2} | grep driver | cut -d ':' -f2 )"

                if [[ -z $str_thisDeviceDriver ]]; then
                    str_thisDeviceDriver="N/A"
                    bool_missingDriver=true

                else
                    if [[ $str_thisDeviceDriver == *"vfio-pci"* ]]; then
                        str_thisDeviceDriver="N/A"
                        bool_foundVFIO=true

                    else
                        str_thisDeviceDriver="${str_thisDeviceDriver##" "}"
                    fi
                fi

                # parameters #
                arr_DeviceIOMMU+=( "$str_thisIOMMU" )
                arr_DevicePCI_ID+=( "$str_thisDevicePCI_ID" )
                arr_DeviceDriver+=( "$str_thisDeviceDriver" )
                arr_DeviceName+=( "$str_thisDeviceName" )
                arr_DeviceType+=( "$str_thisDeviceType" )
                arr_DeviceVendor+=( "$str_thisDeviceVendor" )
            done
        done

        # prioritize worst exit code (place last)
        case true in
            $bool_missingDriver)
                (exit 3);;

            $bool_foundVFIO)
                (exit 254);;
        esac

        case "$?" in
                # function never failed
                0)
                    echo -e "\e[32mSuccessful.\e[0m"
                    true;;

                3)
                    echo -e "\e[32mSuccessful.\e[0m One or more external PCI device(s) missing drivers."
                    true;;

                255)
                    echo -e "\e[31mFailed.\e[0m""";;

                254)
                    echo -e "\e[31mFailed.\e[0m"" Exception: No devices found.";;

                253)
                    echo -e "\e[31mFailed.\e[0m"" Exception: Existing VFIO setup found.";;
            esac

        echo
    }

    function SetupAutoXorg
    {
        # parameters #
        declare -lr str_pwd=$( pwd )

        echo -e "Installing Auto-Xorg... "
        cd $( find -wholename Auto-Xorg | uniq | head -n1 ) && bash ./installer.bash && cd $str_pwd
        PassOrFailThisExitCode
        echo
    }

    function SetupEvdev
    {
        # behavior:
        #
        # ask user to prep setup of Evdev
        # add active desktop users to groups for Libvirt, QEMU, Input devices, etc.
        # write to logfile
        #

        # parameters #
        declare -lr str_thisFile1="qemu-evdev.log"
        declare -lr str_thisFile2="/etc/apparmor.d/abstractions/libvirt-qemu"

        echo -e "Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
        ReadInput "Setup Evdev?"

        if [[ "$?" -eq 0 ]]; then
            # readonly str_firstUser=$( id -u 1000 -n ) && echo -e "Found the first desktop user of the system: $str_firstUser"

            # add users to groups #
            declare -a arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # output to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            ( CreateFile $str_thisFile1 && true ) || false

            if [[ "$?" -eq 0 ]]; then

                # list of input devices #
                declare -lar arr_InputDeviceID=($( ls /dev/input/by-id ))
                declare -lar arr_InputEventDeviceID=($( ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0' ))
                declare -la arr_output_evdevQEMU=()

                # append output #
                for str_element in ${arr_InputDeviceID[@]}; do
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                for str_element in ${arr_InputEventDeviceID[@]}; do
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                readonly arr_output_evdevQEMU

                # append output #
                declare -lar arr_output_evdevApparmor=(
                    "#"
                    "# Evdev #"
                    "  /dev/input/* rw,"
                    "  /dev/input/by-id/* rw,"
                    "#"
                )

                # debug #
                echo -e '${#arr_InputDeviceID[@]}='"'${#arr_InputDeviceID[@]}'"
                echo -e '${#arr_InputEventDeviceID[@]}='"'${#arr_InputEventDeviceID[@]}'"
                echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

                # append file #
                CheckIfFileOrDirExists $str_thisFile1 &> /dev/null

                if [[ "$?" -eq 0 ]]; then
                    for str_element in ${arr_output_evdevQEMU[@]}; do
                            WriteVarToFile $str_thisFile1 $str_element &> /dev/null
                        fi

                        # should this loop fail at any given time, exit
                        else
                            false && break
                        fi
                    done
                fi

                # append system file #
                if [[ "$?" -eq 0 ]]; then
                    for str_element in ${arr_output_evdevApparmor[@]}; do
                        if ( CheckIfFileOrDirExists $str_thisFile2 &> /dev/null == true ); then
                            WriteVarToFile $str_thisFile2 $str_element &> /dev/null

                        # should this loop fail at any given time, exit
                        else
                            false && break
                        fi
                    done
                fi

                # append system file #
                # will require restart of apparmor service or system
                if [[ "$?" -eq 0 ]]; then
                    declare -lr str_output1+="\n  # Evdev #\n  /dev/input/* rw,\n  /dev/input/by-id/* rw,\n"
                    CheckIfFileOrDirExists $str_thisFile2 &> /dev/null && WriteVarToFile $str_thisFile2 $str_output1 && echo $str_thisFile1 &> /dev/null
                fi
            fi
        fi

        PassOrFailThisExitCode "Setup Evdev"
    }

    function SetupHugepages
    {
        # behavior:
        #
        # find vars necessary for Hugepages setup
        # function can never *fail*, just execute or exit
        # write to logfile
        #

        # parameters #
        declare -lr str_thisFile1="qemu-hugepages.log"
        declare -lir int_HostMemMaxK=$( cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 )     # sum of system RAM in KiB
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                                # default output

        echo -e "HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and lower overhead of memory-access (memory latency).\n"
        ReadInput "Setup Hugepages?"

        if [[ "$?" -eq 0 ]]; then

            # add users to groups #
            declare -lar arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # prompt #
            ReadInputFromMultipleChoiceUpperCase "Enter Hugepage size and byte-size [1G/2m]:" "1G" "2M"
            str_HugePageSize=$str_input1

            declare -lir int_HostMemMinK=4194304        # min host RAM in KiB

            # Hugepage Size #
            case $str_HugePageSize in
                "2M")
                    declare -lir int_HugePageK=2048     # Hugepage size
                    declare -lir int_HugePageMin=2;;    # min HugePages

                "1G")
                    declare -lir int_HugePageK=1048576  # Hugepage size
                    declare -lir int_HugePageMin=1;;    # min HugePages
            esac

            declare -lir int_HugePageMemMax=$(( $int_HostMemMaxK - $int_HostMemMinK ))
            declare -lir int_HugePageMax=$(( $int_HugePageMemMax / $int_HugePageK ))       # max HugePages

            # prompt #
            ReadInputFromRangeOfNums "Enter number of HugePages (n * $str_HugePageSize). [$int_HugePageMin <= n <= $int_HugePageMax pages]:" $int_HugePageMin $int_HugePageMax
            declare -ir int_HugePageNum=$str_input1

            # output #
            readonly str_output_hugepagesGRUB="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
            readonly str_output_hugepagesQEMU="hugetlbfs_mount = \"/dev/hugepages\""

            # write to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            CreateFile $str_thisFile1 &> /dev/null

            # if [[ "$?" -eq 0 ]]; then
            #     WriteVarToFile $str_thisFile1 $str_output_hugepagesQEMU && echo
            # fi
        fi

        PassOrFailThisExitCode "Setup Hugepages"
    }

    function SetupStaticCPU_isolation
    {
        function ParseCPU
        {
            # parameters #
            readonly arr_coresByThread=($(cat /proc/cpuinfo | grep 'core id' | cut -d ':' -f2 | cut -d ' ' -f2))
            readonly int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
            readonly int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
            readonly int_SMT_multiplier=$(( $int_totalThreads / $int_totalCores ))
            # declare -a arr_totalCores=()
            declare -a arr_hostCores=()
            declare -a arr_hostThreads=()
            declare -a arr_hostThreadSets=()
            # declare -a arr_virtCores=()
            declare -a arr_virtThreadSets=()
            declare -i int_hostCores=1          # default value

            # reserve remainder cores to host #
            # >= 4-core CPU, leave max 2
            if [[ $int_totalCores -ge 4 ]]; then
                readonly int_hostCores=2

            # 2 or 3-core CPU, leave max 1
            elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then
                readonly int_hostCores=1

            # 1-core CPU, do not reserve cores to virt
            else
                readonly int_hostCores=$int_totalCores
                (exit 255)
            fi

            # group threads for host #
            for (( int_i=0 ; int_i<$int_SMT_multiplier ; int_i++ )); do
                # declare -i int_firstHostCore=$int_hostCores
                declare -i int_firstHostThread=$((int_hostCores+int_totalCores*int_i))
                declare -i int_lastHostCore=$((int_totalCores-1))
                declare -i int_lastHostThread=$((int_lastHostCore+int_totalCores*int_i))

                if [[ $int_firstHostThread -eq $int_lastHostThread ]]; then
                    str_virtThreads+="${int_firstHostThread},"

                else
                    str_virtThreads+="${int_firstHostThread}-${int_lastHostThread},"
                fi
            done

            # update parameters #
            if [[ ${str_virtThreads: -1} == "," ]]; then
                str_virtThreads=${str_virtThreads::-1}
            fi

            # group threads by core id #
            for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do
                str_line1=""
                declare -i int_thisCore=${arr_coresByThread[int_i]}

                for (( int_j=0 ; int_j<$int_SMT_multiplier ; int_j++ )); do
                    int_thisThread=$((int_thisCore+int_totalCores*int_j))
                    str_line1+="$int_thisThread,"

                    if [[ $int_thisCore -lt $int_hostCores ]]; then
                        arr_hostThreads+=("$int_thisThread")
                    fi
                done

                # update    str_output1="Setup 'Static' CPU isolation? [Y/n]: "

                arr_totalThreads+=("$str_line1")

                # save output for cpu isolation (host) #
                if [[ $int_thisCore -lt $int_hostCores ]]; then
                    arr_hostCores+=("$int_thisCore")
                    arr_hostThreadSets+=("$str_line1")

                # save output for cpuset/cpumask (qemu cpu pinning) #
                else
                    # arr_virtCores+=("$int_thisCore")
                    arr_virtThreadSets+=("$str_line1")
                fi
            done

            # update parameters #
            readonly arr_totalThreads
            readonly arr_hostCores
            readonly arr_hostThreadSets
            readonly arr_virtThreadSets

            # save output to string for cpuset and cpumask #
            #
            # example:
            #
            # host 0-1,8-9
            #
            # virt 2-7,10-15
            #
            #
            # cores     bit masks       mask
            # 0-7       0b11111111      FF      # total cores
            # 0,4       0b00010001      11      # host cores
            #
            # 0-11      0b111111111111  FFF     # total cores
            # 0-1,6-7   0b000011000011  C3      # host cores
            #
            # find cpu mask #
            readonly int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))
            declare -i int_hostThreads_mask=0

            for int_thisThread in ${arr_hostThreads[@]}; do
                int_hostThreads_mask+=$(( 2 ** $int_thisThread ))
            done

            # save output #
            if [[ "$?" -eq 0 ]]; then
                readonly int_hostThreads_mask
                readonly hex_totalThreads_mask=$(printf '%x\n' $int_totalThreads_mask)  # int to hex #
                readonly hex_hostThreads_mask=$(printf '%x\n' $int_hostThreads_mask)    # int to hex #
                readonly str_GRUB_CMDLINE_CPU_Isolation="isolcpus=$str_virtThreads nohz_full=$str_virtThreads rcu_nocbs=$str_virtThreads"
            fi
        }

        # prompt #
        echo -e "CPU isolation (Static or Dynamic) is a feature which allocates system CPU threads to the host and Virtual machines (VMs), separately.\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit\n\t'Static' is more 'permanent' CPU isolation: installation will append to GRUB after VFIO setup.\n\tAlternatively, 'Dynamic' CPU isolation is flexible and on-demand: post-installation will execute as a libvirt hook script (per VM)."
        ReadInput "Setup 'Static' CPU isolation?" && echo -en "Executing CPU isolation setup... " && ParseCPU
        PassOrFailThisExitCode
        echo
    }

    function SetupZRAM_Swap
    {
        # parameters #
        declare -lr str_pwd=$( pwd )

        # prompt #
        echo -e "Installing zram-swap... "

        if [[ $( systemctl status asshole &> /dev/null ) != *"could not be found"* ]]; then
            systemctl stop zramswap &> /dev/null
            systemctl disable zramswap &> /dev/null
        fi

        ( cd $( find -wholename zram-swap | uniq | head -n1 ) && sh ./install.sh && cd $str_pwd ) || (exit 255)

        # setup ZRAM #
        if [[ "$?" -eq 0 ]]; then

            # disable all existing zram swap devices
            if [[ $( swapon -v | grep /dev/zram* ) == "/dev/zram"* ]]; then
                swapoff /dev/zram* &> /dev/null
            fi

            declare -ir int_hostMemMaxG=$(( int_HostMemMaxK / 1048576 ))
            declare -ir int_sysMemMaxG=$(( int_hostMemMaxG + 1 ))

            echo -e "Total system memory: <= ${int_sysMemMaxG}G.\nIf 'Z == ${int_sysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."

            # free memory #
            if [[ ! -z $str_HugePageSize && ! -z $int_HugePageNum ]]; then
                case $str_HugePageSize in
                    "1G")
                        declare -ir int_hugePageSizeK=1048576;;

                    "2M")
                        declare -ir int_hugePageSizeK=2048;;
                esac

                declare -ir int_hugepagesMemG=$int_HugePageNum*$int_hugePageSizeK/1048576
                declare -ir int_hostMemFreeG=$int_sysMemMaxG-$int_hugepagesMemG
                echo -e "Free system memory after hugepages (${int_hugepagesMemG}G): <= ${int_hostMemFreeG}G."

            else
                declare -ir int_hostMemFreeG=$int_sysMemMaxG
                echo -e "Free system memory: <= ${int_hostMemFreeG}G."
            fi

            str_output1="Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): "
            echo -en $str_output1
            read -r int_ZRAM_sizeG

            while true; do

                # attempt #
                if [[ $int_count -ge 2 ]]; then
                    ((int_ZRAM_sizeG=int_hostMemFreeG/2))      # default selection
                    echo -e "Exceeded max attempts. Default selection: ${int_ZRAM_sizeG}G"
                    break

                else
                    if [[ -z $int_ZRAM_sizeG || $int_ZRAM_sizeG -lt 0 || $int_ZRAM_sizeG -ge $int_hostMemFreeG ]]; then
                        echo -en "\e[33mInvalid input.\e[0m\n$str_output1"
                        read -r int_ZRAM_sizeG

                    else
                        break
                    fi
                fi

                ((int_count++))
            done

            declare -ir int_denominator="(( $int_sysMemMaxG / $int_ZRAM_sizeG ))"
            str_output1="\n_zram_fraction=\"1/$int_denominator\""
            # str_outFile1="/etc/default/zramswap"
            str_outFile1="/etc/default/zram-swap"

            CreateBackupFromFile $str_outFile1
            WriteVarToFile $str_outFile1 $str_output1 || (exit 255)
        fi

        echo -en "Zram-swap setup "

        case "$?" in
            0)
                echo -e "\e[32mSuccessful.\e[0m"
                true;;

            255)
                echo -e "\e[31mFailed.\e[0m""";;

            254)
                echo -e "\e[31mFailed.\e[0m"" Null exception/invalid input.";;
        esac

        echo
    }
##

## executive functions ##
    function main
    {
        # checks #
        CheckIfUserIsRoot
        CheckIfIOMMU_IsEnabled

        # pre setup #
            # parameters #
            declare -lr str_file1="etc_libvirt_qemu.conf"
            # declare -lr str_file2="/etc/libvirt/qemu.conf"
            declare -lr str_file2="test-qemu.conf"            # debug

            CreateFile $str_file2                             # debug

            # restore system file from repo backup if local backups do not exist #
            # if ( CheckIfFileOrDirExists $str_file1 == true && CheckIfFileOrDirExists $str_file2 == false); then
            #     cp $str_file1 $str_file2
            # fi

            # append to system file #
            declare -la arr_output1=(
                "# Generated by 'portellam/deploy-VFIO-setup'"
                "#"
                "# WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
                "#"
                "# Run 'systemctl restart libvirtd.service' to update."
                " "
                "# User permissions #"
                "#     user = \"user\""
                "#     group = \"user\""
                "#"
            )

            # find first desktop user, add user to groups for libvirt/qemu, hugepages, and evdev
            readonly str_firstUser=$( id -u 1000 -n ) && (
                adduser $str_firstUser libvirt &> /dev/null
                adduser $str_firstUser input &> /dev/null
                bool=true
                ) || bool=false

            # append to system file #
            if [[ $bool == true ]]; then
                arr_output1+=(
                    "user = \"${str_firstUser}\""
                    "group = \"user\""
                    "#"
                )
            fi

            # execute Hugepages setup #
            bool_isHugepagesSetup=false
            SetupHugepages && bool_isHugepagesSetup=true

            # echo -e "str_GRUB_CMDLINE_Hugepages:'${str_GRUB_CMDLINE_Hugepages}'"  # this scope does work!

            # append #
            if [[ $bool_isHugepagesSetup == true ]]; then
                arr_output1+=("${str_output_hugepagesQEMU}")
                # arr_output1+=($( cat $str_thisFile1 ))
                arr_output1+=("#")
            fi

            # append #
            arr_output1+=(
                "cgroup_device_acl = ["
                "    \"/dev/null\", \"/dev/full\", \"/dev/zero\","
                "    \"/dev/random\", \"/dev/urandom\","
                "    \"/dev/ptmx\", \"/dev/kvm\","
                "    \"/dev/rtc\",\"/dev/hpet\""
            )

            # execute Evdev setup #
            bool_isEvdevSetup=false
            SetupEvdev && bool_isEvdevSetup=true

            # append #
            if [[ $bool_isEvdevSetup == true ]]; then
                echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

                for str_element in ${arr_output_evdevQEMU[@]}; do
                    arr_output+=("${str_element}")
                done

                # arr_output1+=($( cat $str_thisFile1 ))
                arr_output1+=("#")
            fi

            # append #
            arr_output1+=(
                "]"
                "#"
            )

            if ( CreateBackupFromFile $str_file2 &> /dev/null == true ); then
                for str_element in ${arr_output1[@]}; do
                    if [[ "$?" -ne 0 ]]; then
                        break
                    fi

                    ( WriteVarToFile $str_file2 $str_element &> /dev/null && true ) || ( bool_fail_outputIsQuiet && false )
                done

            else
                echo -e "\e[33mWARNING:\e[0m"" Setup cannot continue." && ExitWithThisExitCode
            fi

        exit 0
        SetupStaticCPU_isolation && bool_isCPU_staticIsolationSetup=true

        # TO-DO: add check for necessary dependencies or packages

        if [[ TestNetwork == true ]]; then

            # zram-swap #
            if ( CloneOrUpdateGitRepositories "FoundObjects/zram-swap" ); then
                SetupZRAM_Swap && bool_isZRAM_swapSetup=true
            fi

            # auto-xorg #
            if ( CloneOrUpdateGitRepositories "portellam/auto-xorg" ); then
                SetupAutoXorg && bool_isAutoXorgSetup=true
            fi

        else

            # zram-swap #
            if ( CheckIfFileOrDirExists "zram-swap" == true ); then
                SetupZRAM_Swap && bool_isZRAM_swapSetup=true
            fi

            # auto-xorg #
            if ( CheckIfFileOrDirExists "auto-xorg" ); then
                SetupAutoXorg && bool_isAutoXorgSetup=true
            fi
        fi

        if [[ $bool_isAutoXorgSetup == false && $bool_isCPU_staticIsolationSetup == false && $bool_isHugepagesSetup == false && $bool_isZRAM_swapSetup == false ]]; then
            echo -e "\e[33mWARNING:\e[0m"" Failed pre-setup."
        fi
    }
##

## execution ##
    # NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    main
##