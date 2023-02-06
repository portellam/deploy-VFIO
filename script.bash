#!/bin/bash sh

#
# Filename:         deploy-VFIO-setup.bash
# Description:      The Ultimate script to seamlessly deploy a VFIO setup (PCI passthrough).
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

#
# TODO
# -Continuous Improvement: after conclusion of this script's dev. Propose a refactor using the bashful libraries and with better Bash principles in mind.
# -demo the product: get a working, debuggable version ASAP.
# -revise README, files
# -pull down original system files from somewhere
# -or provide checksum of my backups of system files
#
#

# <summary> #1 - Command operation and validation, and Miscellaneous </summary>
# <code>
    # <summary> Append Pass or Fail given exit code. </summary>
    # <param name="${int_exit_code}"> the last exit code </param>
    # <param name="${1}"> string: the output statement </param>
    # <returns> output statement </returns>
    function AppendPassOrFail
    {
        SaveExitCode
        CheckIfVarIsValid "${1}" &> /dev/null && echo -en "${1} "

        case "${int_exit_code}" in
            0 )
                echo -e "${var_suffix_pass}"
                ;;

            "${int_code_partial_completion}" )
                echo -e "${var_suffix_maybe}"
                ;;

            "${int_code_skipped_operation}" )
                echo -e "${var_suffix_skip}"
                ;;

            * )
                echo -e "${var_suffix_fail}"
                ;;
        esac

        return "${int_exit_code}"
    }

    # <summary> Redirect current directory to shell script root directory. </summary>
    # <param name="${1}"> string: the shell script name </param>
    # <returns> exit code </returns>
    function GoToScriptDir
    {
        cd $( dirname "${0}" ) || return 1
        return 0
    }

    # <summary> Parse and execute from a list of command(s) </summary>
    # <param name="${arr_commands}"> string of array: the list of command(s) </param>
    # <param name="${arr_commands_output}"> string of array: the list of output statements for each command call </param>
    # <returns> exit code </returns>
    function ParseAndExecuteListOfCommands
    {
        # <params>
        declare -aI arr_commands
        declare -aI arr_commands_output
        local readonly str_output_fail="${var_prefix_error} Execution of command failed."
        # </params>

        CheckIfVarIsValid "${arr_commands[@]}" || return "${?}"

        for int_key in ${!arr_commands[@]}; do
            local var_command="${arr_commands[$int_key]}"
            local var_command_output="${arr_commands_output[$int_key]}"
            local str_output="Execute '${var_command}'?"

            if CheckIfVarIsValid "${var_command_output}" &> /dev/null; then
                str_output="${var_command_output}"
            fi

            if ReadInput "${str_output}"; then
                ( eval "${var_command}" ) || ( SaveExitCode; echo -e "${str_output_fail}" )
            fi
        done

        return "${int_exit_code}"
    }

    # <summary> Save last exit code. </summary>
    # <param name=""${int_exit_code}""> the exit code </param>
    # <returns> void </returns>
    function SaveExitCode
    {
        int_exit_code="${?}"
    }

    # <summary> Attempt given command a given number of times before failure. </summary>
    # <param name="${1}"> string: the command to execute </param>
    # <returns> exit code </returns>
    function TryThisXTimesBeforeFail
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        local readonly str_output_fail="${var_prefix_error} Execution of command failed."
        # </params>

        for int_count in ${arr_count[@]}; do
            eval "${1}" && return 0 || echo -e "${str_output_fail}"
        done

        return 1
    }
# </code>

# <summary> #2 - Data-type and variable validation </summary>
# <code>
    # <summary> Check if the command is installed. </summary>
    # <param name="${1}"> string: the command </param>
    # <returns> exit code </returns>
    function CheckIfCommandIsInstalled
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Command '${1}' is not installed."
        local readonly var_actual_install_path=$( command -v "${1}" )
        local readonly var_expected_install_path="/usr/bin/${1}"
        # </params>

        # if $( ! CheckIfFileExists $var_actual_install_path ) &> /dev/null || [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
        # if ! CheckIfFileExists $var_actual_install_path &> /dev/null; then

        if [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_cmd_is_null}"
        fi

        return 0
    }

    # <summary> Check if the daemon is active or not. </summary>
    # <param name="${1}"> string: the command </param>
    # <returns> exit code </returns>
    function CheckIfDaemonIsActiveOrNot
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly var_keyword_true='active'
        local readonly var_keyword_false='inactive'
        local readonly var_command='systemctl status ${1} | grep "${var_keyword_true}"'
        local readonly var_command_output=$( eval "${var_command}" )
        # </params>

        CheckIfVarIsValid "${var_command_output}" || return "${?}"

        if [[ "${var_command_output}" == *"${var_keyword_false}"* ]]; then
            return 1
        fi

        return 0
    }

    # <summary> Check if the daemon is installed. </summary>
    # <param name="${1}"> string: the command </param>
    # <returns> exit code </returns>
    function CheckIfDaemonIsInstalled
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Daemon '${1}' is not installed."
        local readonly var_command='systemctl status ${1} | grep -Eiv "not"'
        local readonly var_command_output=$( eval "${var_command}" )
        # </params>

        if ! CheckIfVarIsValid "${var_command_output}"; then
            echo -e "${str_output_fail}"
            return "${int_code_cmd_is_null}"
        fi

        return 0
    }

    # <summary> Check if the process is active. </summary>
    # <param name="${1}"> string: the command </param>
    # <returns> exit code </returns>
    function CheckIfProcessIsActive
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Process '${1}' is not active."
        local readonly var_command='ps -e | grep ${1}'
        local readonly var_command_output=$( eval "${var_command}" )
        # </params>

        if ! CheckIfVarIsValid "${var_command_output}"; then
            echo -e "${str_output_fail}"
            return "${int_code_cmd_is_null}"
        fi

        return 0
    }

    # <summary> Check if the array is empty. </summary>
    # <param name="${arr}"> array: the array </param>
    # <returns> exit code </returns>
    function CheckIfArrayIsEmpty
    {
        # <params>
        local readonly str_output_var_is_null="${var_prefix_error} Null string."
        local readonly str_output_var_is_empty="${var_prefix_error} Empty string."
        # </params>

        for var_element in "${arr[@]}"; do
            CheckIfVarIsValid "${var_element}" &> /dev/null && return 0
        done

        echo -e "${str_output_var_is_empty}"
        return "${int_code_var_is_empty}"
    }

    # <summary> Check if the value is a valid bool. </summary>
    # <param name="${1}"> var: the boolean </param>
    # <returns> exit code </returns>
    function CheckIfVarIsBool
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Not a boolean."
        # </params>

        case "${1}" in
            "true" | "false" )
                return 0
                ;;

            * )
                echo -e "${str_output_fail}"
                return "${int_code_var_is_not_bool}"
                ;;
        esac
    }

    # <summary> Check if the value is a valid number. </summary>
    # <param name="${1}"> var: the number </param>
    # <returns> exit code </returns>
    function CheckIfVarIsNum
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_num_regex='^[0-9]+$'
        local readonly str_output_fail="${var_prefix_error} NaN."
        # </params>

        if ! [[ "${1}" =~ $str_num_regex ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_var_is_NAN}"
        fi

        return 0
    }

    # <summary> Check if the value is valid. </summary>
    # <param name="${1}"> string: the variable </param>
    # <returns> exit code </returns>
    function CheckIfVarIsValid
    {
        # <params>
        local readonly str_output_var_is_null="${var_prefix_error} Null string."
        local readonly str_output_var_is_empty="${var_prefix_error} Empty string."
        # </params>

        if [[ -z "${1}" ]]; then
            echo -e "${str_output_var_is_null}"
            return "${int_code_var_is_null}"
        fi

        if [[ "${1}" == "" ]]; then
            echo -e "${str_output_var_is_empty}"
            return "${int_code_var_is_empty}"
        fi

        return 0
    }

    # <summary> Check if the directory exists. </summary>
    # <param name="${1}"> string: the directory </param>
    # <returns> exit code </returns>
    function CheckIfDirExists
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Directory '${1}' does not exist."
        # </params>

        if [[ ! -d "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_dir_is_null}"
        fi

        return 0
    }

    # <summary> Check if the file exists. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CheckIfFileExists
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' does not exist."
        # </params>

        if [[ ! -e "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_null}"
        fi

        return 0
    }

    # <summary> Check if the file is executable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CheckIfFileIsExecutable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not executable."
        # </params>

        if [[ ! -x "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_not_executable}"
        fi

        return 0
    }

    # <summary> Check if the file is readable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CheckIfFileIsReadable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not readable."
        # </params>

        if [[ ! -r "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_not_readable}"
        fi

        return 0
    }

    # <summary> Check if the file is writable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CheckIfFileIsWritable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not writable."
        # </params>

        if [[ ! -w "${1}" ]]; then
            echo -e "${str_output_fail}"
            return $int_code_file_is_not_writable
        fi

        return 0
    }

    # <summary> Parse exit code as boolean. If non-zero, return false. </summary>
    # <param name="${?}"> int: the exit code </param>
    # <returns> boolean </returns>
    function ParseExitCodeAsBool
    {
        if [[ "${?}" -ne 0 ]]; then
            echo false
            return 1
        fi

        echo true
        return 0
    }
# </code>

# <summary> #3 - User validation </summary>
# <code>
    # <summary> Check if current user is sudo or root. </summary>
    # <returns> exit code </returns>
    function CheckIfUserIsRoot
    {
        # <params>
        local readonly str_file=$( basename "${0}" )
        local readonly str_output_user_is_not_root="${var_prefix_warn} User is not Sudo/Root. In terminal, enter: ${var_yellow}'sudo bash ${str_file}'${var_reset_color}."
        # </params>

        if [[ $( whoami ) != "root" ]]; then
            echo -e "${str_output_user_is_not_root}"
            return 1
        fi

        return 0
    }
# </code>

# <summary> #4 - File operation and validation </summary>
# <code>
    # <summary> Check if two given files are the same. </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <parameter name="${2}"> string: the file </parameter>
    # <returns> exit code </returns>
    function CheckIfTwoFilesAreSame
    {
        ( CheckIfFileExists "${1}" && CheckIfFileExists "${2}" ) || return "${?}"
        cmp -s "${1}" "${2}" || return 1
        return 0
    }

    # <summary> Create latest backup of given file (do not exceed given maximum count). </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <returns> exit code </returns>
    function CreateBackupFile
    {
        function CreateBackupFile_Main
        {
            CheckIfFileExists "${1}" || return "${?}"

            # <params>
            declare -ir int_max_count=4
            local readonly str_dir1=$( dirname "${1}" )
            local readonly str_suffix=".old"
            local readonly var_command='ls "${str_dir1}" | grep "${1}" | grep $str_suffix | uniq | sort -V'
            declare -a arr_dir1=( $( eval "${var_command}" ) )
            # </params>

            # <summary> Create backup file if none exist. </summary>
            if [[ "${#arr_dir1[@]}" -eq 0 ]]; then
                cp "${1}" "${1}.${var_first_index}${str_suffix}" || return 1
                return 0
            fi

            # <summary> Oldest backup file is same as original file. </summary>
            CheckIfTwoFilesAreSame "${1}" "${arr_dir1[0]}" && return 0

            # <summary> Get index of oldest backup file. </summary>
            local str_oldest_file="${arr_dir1[0]}"
            str_oldest_file="${str_oldest_file%%"${str_suffix}"*}"
            local var_first_index="${str_oldest_file##*.}"
            CheckIfVarIsNum "$var_first_index" || return "${?}"

            # <summary> Delete older backup files, if total matches/exceeds maximum. </summary>
            while [[ "${#arr_dir1[@]}" -gt "$int_max_count" ]]; do
                DeleteFile "${arr_dir1[0]}" || return "${?}"
                arr_dir1=( $( eval "${var_command}" ) )
            done

            # <summary> Increment number of last backup file index. </summary>
            local str_newest_file="${arr_dir1[-1]}"
            str_newest_file="${str_newest_file%%"${str_suffix}"*}"
            local var_last_index="${str_newest_file##*.}"
            CheckIfVarIsNum "${var_last_index}" || return "${?}"
            (( var_last_index++ ))

            # <summary> Newest backup file is different and newer than original file. </summary>
            if ( ! CheckIfTwoFilesAreSame "${1}" "${arr_dir1[-1]}" &> /dev/null ) && [[ "${1}" -nt "${arr_dir1[-1]}" ]]; then
                cp "${1}" "${1}.${var_last_index}${str_suffix}" || return 1
            fi

            return 0
        }

        # <params>
        local readonly str_output="Creating backup file..."
        # </params>

        echo -e "${str_output}"
        CreateBackupFile_Main "${1}"
        AppendPassOrFail "${str_output}"
        return "${?}"
    }

    # <summary> Create a directory. </summary>
    # <param name="${1}"> string: the directory </param>
    # <returns> exit code </returns>
    function CreateDir
    {
        CheckIfDirExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create directory '${1}'."
        # </params>

        mkdir -p "${1}" || (
            echo -e "${str_output_fail}"
            return 1
        )

        return 0
    }

    # <summary> Create a file. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CreateFile
    {
        CheckIfFileExists "${1}" &> /dev/null && return 0

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create file '${1}'."
        # </params>

        if ! touch "${1}" &> /dev/null; then
            echo -e "${str_output_fail}"
            return 1
        fi

        return 0
    }

    # <summary> Delete a dir/file. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function DeleteFile
    {
        CheckIfFileExists "${1}" || return 0

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not delete file '${1}'."
        # </params>

        rm "${1}" || (
            echo -e "${str_output_fail}"
            return 1
        )

        return 0
    }

    # <summary> Output a file. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function PrintFile
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local str_output="Contents for file ${var_yellow}'${1}'${var_reset_color}:"
        local readonly var_command='cat "${1}"'
        # </params>

        echo -e "${str_output}"
        ReadFile "${1}" || return "${?}"
        echo "${var_yellow}"
        eval "${var_command}"
        echo -e "${var_reset_color}\n"

        return 0
    }

    # <summary> Output an array. Declare inherited params before calling this function. </summary>
    # <param name="${arr_output[@]}"> string of array: the array </param>
    # <returns> exit code </returns>
    function PrintArray
    {
        # <params>
        IFS=$'\n'
        declare -aI arr_output
        local readonly var_command='echo -e "${var_yellow}${arr_output[*]}${var_reset_color}"'
        # </params>

        if ! CheckIfVarIsValid "${arr_output[@]}" &> /dev/null; then
            return 1
        fi

        echo
        eval "${var_command}" || return 1
        return 0
    }

    # <summary> Read input from a file. Declare inherited params before calling this function. </summary>
    # <param name="${1}"> string: the file </param>
    # <param name="${arr_file[@]}"> string of array: the file contents </param>
    # <returns> exit code </returns>
    function ReadFile
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        declare -aI arr_file
        local readonly str_output_fail="${var_prefix_fail} Could not read from file '${1}'."
        local readonly var_command='cat "${1}"'
        # </params>

        arr_file=( $( eval "${var_command}" ) )

        if ! CheckIfVarIsValid "${arr_file[@]}" &> /dev/null; then
            echo -e "${str_output_fail}"
            return 1
        fi

        return 0
    }

    # <summary> Restore latest valid backup of given file. </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <returns> exit code </returns>
    function RestoreBackupFile
    {
        function RestoreBackupFile_Main
        {
            CheckIfFileExists "${1}" || return "${?}"

            # <params>
            local bool=false
            local readonly str_dir1=$( dirname "${1}" )
            local readonly str_suffix=".old"
            var_command='ls "${str_dir1}" | grep "${1}" | grep $str_suffix | uniq | sort -rV'
            declare -a arr_dir1=( $( eval "${var_command}" ) )
            # </params>

            CheckIfVarIsValid ${arr_dir1[@]} || return "${?}"

            for var_element1 in ${arr_dir1[@]}; do
                CheckIfFileExists "${var_element1}" && cp "${var_element1}" "${1}" && return 0
            done

            return 1
        }

        # <params>
        local readonly str_output="Restoring backup file..."
        # </params>

        echo -e "${str_output}"
        RestoreBackupFile_Main "${1}"
        AppendPassOrFail "${str_output}"

        return "${int_exit_code}"
    }

    # <summary> Write output to a file. Declare inherited params before calling this function. </summary>
    # <param name="${1}"> string: the file </param>
    # <param name="${arr_file[@]}"> array: the file contents </param>
    # <returns> exit code </returns>
    function WriteFile
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        declare -aI arr_file
        local readonly str_output_fail="${var_prefix_fail} Could not write to file '${1}'."
        # </params>

        CheckIfVarIsValid "${arr_file[@]}" || return "${?}"

        # new
        ( printf "%s\n" "${arr_file[@]}" >> "${1}" ) || (
            echo -e "${str_output_fail}"
            return 1
        )

        # old
        # for var_element in ${arr_file[@]}; do
        #     echo -e "${var_element}" >> "${1}" || (
        #         echo -e "${str_output_fail}"
        #         return 1
        #     )
        # done

        return 0
    }

    # <summary> Write output to a file. Declare inherited params before calling this function. </summary>
    # <param name="${1}"> string: the file </param>
    # <param name="${arr_file[@]}"> array: the file contents </param>
    # <returns> exit code </returns>
    function OverwriteFile
    {
        # <params>
        declare -aI arr_file
        # </params>

        DeleteFile "${1}"
        CreateFile "${1}" || return "${?}"
        WriteFile "${1}"
        return "${?}"
    }
# </code>

# <summary> #5 - Device validation </summary>
# <code>
    # <summary> Check if current kernel and distro are supported, and if the expected Package Manager is installed. </summary>
    # <returns> exit code </returns>
    function CheckLinuxDistro
    {
        # <params>
        local readonly str_kernel="$( uname -o | tr '[:upper:]' '[:lower:]' )"
        local readonly str_operating_system="$( lsb_release -is | tr '[:upper:]' '[:lower:]' )"
        local readonly str_output_distro_is_not_valid="${var_prefix_error} Distribution '$( lsb_release -is )' is not supported."
        local readonly str_output_kernel_is_not_valid="${var_prefix_error} Kernel '$( uname -o )' is not supported."
        local readonly str_OS_with_apt="debian bodhi deepin knoppix mint peppermint pop ubuntu kubuntu lubuntu xubuntu "
        local readonly str_OS_with_dnf_yum="redhat berry centos cern clearos elastix fedora fermi frameos mageia opensuse oracle scientific suse"
        local readonly str_OS_with_pacman="arch manjaro"
        local readonly str_OS_with_portage="gentoo"
        local readonly str_OS_with_urpmi="opensuse"
        local readonly str_OS_with_zypper="mandriva mageia"
        # </params>

        ( CheckIfVarIsValid "${str_kernel}" &> /dev/null && CheckIfVarIsValid "${str_operating_system}" &> /dev/null ) || return "${?}"

        if [[ "${str_kernel}" != *"linux"* ]]; then
            echo -e "${str_output_kernel_is_not_valid}"
            return 1
        fi

        # <summary> Check if current Operating System matches Package Manager, and Check if PM is installed. </summary>
        # <returns> exit code </returns>
        function CheckLinuxDistro_GetPackageManagerByOS
        {
            if [[ "${str_OS_with_apt}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="apt"

            elif [[ "${str_OS_with_dnf_yum}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="dnf"
                CheckIfCommandIsInstalled "${str_package_manager}" &> /dev/null && return 0
                str_package_manager="yum"

            elif [[ "${str_OS_with_pacman}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="pacman"

            elif [[ "${str_OS_with_portage}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="portage"

            elif [[ "${str_OS_with_urpmi}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="urpmi"

            elif [[ "${str_OS_with_zypper}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="zypper"

            else
                str_package_manager=""
                return 1
            fi

            CheckIfCommandIsInstalled "${str_package_manager}" &> /dev/null && return 0
            return 1
        }

        if ! CheckLinuxDistro_GetPackageManagerByOS; then
            echo -e "${str_output_distro_is_not_valid}"
            return 1
        fi

        return 0
    }

    # <summary> Test network connection to Internet. Ping DNS servers by address and name. </summary>
    # <param name="${1}"> boolean: true/false set/unset verbosity </param>
    # <returns> exit code </returns>
    function TestNetwork
    {
        # <params>
        local bool=false
        # </params>

        if CheckIfVarIsBool "${1}" &> /dev/null && "${1}"; then
            local bool="${1}"
        fi

        if $bool; then
            echo -en "Testing Internet connection...\t"
        fi

        ( ping -q -c 1 8.8.8.8 || ping -q -c 1 1.1.1.1 ) &> /dev/null || false

        SaveExitCode

        if $bool; then
            ( return "${int_exit_code}" )
            AppendPassOrFail
            echo -en "Testing connection to DNS...\t"
        fi

        ( ping -q -c 1 www.google.com && ping -q -c 1 www.yandex.com ) &> /dev/null || false

        SaveExitCode

        if $bool; then
            ( return "${int_exit_code}" )
            AppendPassOrFail
        fi

        if [[ "${int_exit_code}" -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        return "${int_exit_code}"
    }

    # <summary> Update TestNetwork </summary>
    # <param name="${bool_is_connected_to_Internet}"> boolean: network status </param>
    # <returns> exit code </returns>
    function UpdateNetworkStatus
    {
        # <params>
        declare -I bool_is_connected_to_Internet
        # </params>

        ( TryThisXTimesBeforeFail "TestNetwork true" && bool_is_connected_to_Internet=true ) || bool_is_connected_to_Internet=false
    }
# </code>

# <summary> #6 - User input </summary>
# <code>
    # <summary> Ask user Yes/No, read input and return exit code given answer. </summary>
    # <param name="${1}"> string: the output statement </param>
    # <returns> exit code </returns>
    function ReadInput
    {
        # <params>
        declare -i int_max_tries=3
        declare -ar arr_count=( $( seq 0 "${int_max_tries}" ) )
        local readonly str_no="N"
        local readonly str_yes="Y"
        local str_output=""
        # </params>

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        str_output+="${var_green}[Y/n]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do

            # <summary> Append output. </summary>
            echo -en "${str_output} "
            read var_input
            var_input=$( echo $var_input | tr '[:lower:]' '[:upper:]' )

            # <summary> Check if input is valid. </summary>
            if CheckIfVarIsValid $var_input; then
                case $var_input in
                    ""${str_yes}"" )
                        return 0;;
                    "${str_no}" )
                        return 1;;
                esac
            fi

            # <summary> Input is not valid. </summary>
            echo -e "${str_output_var_is_not_valid}"
        done

        # <summary> After given number of attempts, input is set to default. </summary>
        str_output="Exceeded max attempts. Choice is set to default: ${var_yellow}${str_no}${var_reset_color}"
        echo -e "${str_output}"
        return 1
    }

    # <summary>
    # Ask for a number, within a given range, and return given number.
    # If input is not valid, return minimum value. Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <parameter name="${2}"> num: absolute minimum </parameter>
    # <parameter name="${3}"> num: absolute maximum </parameter>
    # <parameter name="$var_input"> the answer </parameter>
    # <returns> $var_input </returns>
    function ReadInputFromRangeOfTwoNums
    {
        # <params>
        declare -i int_max_tries=3
        declare -ar arr_count=( $( seq 0 "${int_max_tries}" ) )
        local readonly var_min="${2}"
        local readonly var_max="${3}"
        local str_output=""
        local readonly str_output_extrema_are_not_valid="${var_prefix_error} Extrema are not valid."
        var_input=""
        # </params>

        if ( ! CheckIfVarIsNum $var_min || ! CheckIfVarIsNum $var_max ) &> /dev/null; then
            echo -e "${str_output}"_extrema_are_not_valid
            return 1
        fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "

        str_output+="${var_green}[${var_min}-${var_max}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do

            # <summary> Append output. </summary>
            echo -en "${str_output} "
            read var_input

            # <summary> Check if input is valid. </summary>
            if CheckIfVarIsNum $var_input && [[ $var_input -ge $var_min && $var_input -le $var_max ]]; then
                return 0
            fi

            # <summary> Input is not valid. </summary>
            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=$var_min
        str_output="Exceeded max attempts. Choice is set to default: ${var_yellow}${var_input}${var_reset_color}"
        echo -e "${str_output}"
        return 1
    }

    # <summary>
    # Ask user for multiple choice, and return choice given answer.
    # If input is not valid, return first value. Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <param name="${2}" name="${3}" name="${4}" name="${5}" name="${6}" name="${7}" name="${8}"> multiple choice </param>
    # <param name="$var_input"> the answer </param>
    # <returns> the answer </returns>
    function ReadMultipleChoiceIgnoreCase
    {
        # <params>
        declare -i int_max_tries=3
        declare -ar arr_count=( $( seq 0 "${int_max_tries}" ) )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            SaveExitCode
            echo -e "${str_output_multiple_choice_not_valid}"
            return "${int_exit_code}"
        fi

        arr_input+=( "${2}" )
        arr_input+=( "${3}" )

        if CheckIfVarIsValid "${4}" &> /dev/null; then arr_input+=( "${4}" ); fi
        if CheckIfVarIsValid "${5}" &> /dev/null; then arr_input+=( "${5}" ); fi
        if CheckIfVarIsValid "${6}" &> /dev/null; then arr_input+=( "${6}" ); fi
        if CheckIfVarIsValid "${7}" &> /dev/null; then arr_input+=( "${7}" ); fi
        if CheckIfVarIsValid "${8}" &> /dev/null; then arr_input+=( "${8}" ); fi
        if CheckIfVarIsValid "${9}" &> /dev/null; then arr_input+=( "${9}" ); fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        str_output+="${var_green}[${arr_input[@]}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do
            echo -en "${str_output} "
            read var_input

            if CheckIfVarIsValid $var_input; then
                var_input=$( echo $var_input | tr '[:lower:]' '[:upper:]' )

                for var_element in ${arr_input[@]}; do
                    if [[ "${var_input}" == $( echo $var_element | tr '[:lower:]' '[:upper:]' ) ]]; then
                        var_input=$var_element
                        return 0
                    fi
                done
            fi

            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=${arr_input[0]}
        str_output="Exceeded max attempts. Choice is set to default: ${var_yellow}${var_input}${var_reset_color}"
        echo -e "${str_output}"
        return 1
    }

    # <summary>
    # Ask user for multiple choice, and return given choice.
    # If input is not valid, return first value.
    # Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <param name="${2}" name="${3}" name="${4}" name="${5}" name="${6}" name="${7}" name="${8}"> multiple choice </param>
    # <param name="$var_input"> the answer </param>
    # <returns> the answer </returns>
    function ReadMultipleChoiceMatchCase
    {
        # <params>
        declare -i int_max_tries=3
        declare -ar arr_count=( $( seq 0 "${int_max_tries}" ) )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            echo -e "${str_output_multiple_choice_not_valid}"
            return 1;
        fi

        arr_input+=( "${2}" )
        arr_input+=( "${3}" )

        if CheckIfVarIsValid "${4}" &> /dev/null; then arr_input+=( "${4}" ); fi
        if CheckIfVarIsValid "${5}" &> /dev/null; then arr_input+=( "${5}" ); fi
        if CheckIfVarIsValid "${6}" &> /dev/null; then arr_input+=( "${6}" ); fi
        if CheckIfVarIsValid "${7}" &> /dev/null; then arr_input+=( "${7}" ); fi
        if CheckIfVarIsValid "${8}" &> /dev/null; then arr_input+=( "${8}" ); fi
        if CheckIfVarIsValid "${9}" &> /dev/null; then arr_input+=( "${9}" ); fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        str_output+="${var_green}[${arr_input[@]}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do
            echo -en "${str_output} "
            read var_input

            if CheckIfVarIsValid $var_input &> /dev/null; then
                for var_element in ${arr_input[@]}; do
                    if [[ "${var_input}" == "${var_element}" ]]; then
                        var_input=$var_element
                        return 0
                    fi
                done
            fi

            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=${arr_input[0]}
        str_output="Exceeded max attempts. Choice is set to default: ${var_yellow}${var_input}${var_reset_color}"
        echo -e "${str_output}"
        return 1
    }
# </code>

# <summary> #7 - Software installation </summary>
# <code>
    # <summary> Distro-agnostic, Check if package exists on-line. </summary>
    # <param name="${1}"> string: the software package(s) </param>
    # <returns> exit code </returns>
    function CheckIfPackageExists
    {
        ( CheckIfVarIsValid "${1}" && CheckIfVarIsValid "${str_package_manager}" )|| return "${?}"

        # <params>
        local str_commands_to_execute=""
        local readonly str_output="${var_prefix_fail}: Command '${str_package_manager}' is not supported."
        # </params>

        case "${str_package_manager}" in
            "apt" )
                str_commands_to_execute="apt list ${1}"
                ;;

            "dnf" )
                str_commands_to_execute="dnf search ${1}"
                ;;

            "pacman" )
                str_commands_to_execute="pacman -Ss ${1}"
                ;;

            "gentoo" )
                str_commands_to_execute="emerge --search ${1}"
                ;;

            "urpmi" )
                str_commands_to_execute="urpmq ${1}"
                ;;

            "yum" )
                str_commands_to_execute="yum search ${1}"
                ;;

            "zypper" )
                str_commands_to_execute="zypper se ${1}"
                ;;

            * )
                echo -e "${str_output}"
                return 1
                ;;
        esac

        eval "${str_commands_to_execute}" || return 1
    }

    # <summary> Check if system file is original or not. </summary>
    # <parameter name="${1}"> string: the system file </parameter>
    # <parameter name="${2}"> string: the software package(s) to install </parameter>
    # <parameter name="${bool_is_connected_to_Internet}"> boolean: TestNetwork </parameter>
    # <returns> exit code </returns>
    function CheckIfSystemFileIsOriginal
    {
        CheckIfVarIsValid "${1}" || return "${?}"
        CheckIfVarIsValid "${2}" || return "${?}"

        # <params>
        local bool_backup_file_exists=false
        local bool_system_file_is_original=false
        local readonly str_backup_file="${1}.bak"
        # </params>

        # <summary> Original system file does not exist. </summary>
        if $bool_is_connected_to_Internet && ! CheckIfFileExists "${1}"; then
            InstallPackage "${2}" true && bool_system_file_is_original=true
        fi

        # if CreateBackupFile "${1}"; then                                      # CreateBackupFile is broken?
        #     bool_backup_file_exists=true
        # fi

        if cp "${1}" "${str_backup_file}" && CheckIfFileExists "${1}"; then
            bool_backup_file_exists=true
        else
            return 1
        fi

        # <summary> It is unknown if system file *is* original. </summary>
        if $bool_is_connected_to_Internet && $bool_backup_file_exists && ! $bool_system_file_is_original; then
            DeleteFile "${1}"
            InstallPackage "${2}" true && bool_system_file_is_original=true
        fi

        # <summary> System file *is not* original. Attempt to restore backup. </summary>
        if $bool_backup_file_exists && ! $bool_system_file_is_original; then
            # RestoreBackupFile "${1}"                                          # RestoreBackupFile is broken?
            cp "${str_backup_file}" "${1}" || return 1
        fi

        # <summary> Do no work. </summary>
        # if ! $bool_backup_file_exists || ! $bool_system_file_is_original; then
        #     return 1
        # fi

        if ! $bool_system_file_is_original; then
            return 1
        fi

        return 0
    }

    # <summary> Distro-agnostic, Install a software package. </summary>
    # <param name="${1}"> string: the software package(s) </param>
    # <param name="${2}"> boolean: true/false do/don't reinstall software package and configuration files (if possible) </param>
    # <param name="${str_package_manager}"> string: the package manager </param>
    # <returns> exit code </returns>
    function InstallPackage
    {
        CheckIfVarIsValid "${1}" || return "${?}"
        CheckIfVarIsValid "${str_package_manager}" || return "${?}"

        # <params>
        local bool_option_reinstall=false
        local str_commands_to_execute=""
        local readonly str_output="Installing software packages..."
        local readonly str_output_fail="${var_prefix_fail}: Command '${str_package_manager}' is not supported."
        # </params>

        CheckIfVarIsBool "${2}" &> /dev/null && bool_option_reinstall=true

        # <summary> Auto-update and auto-install selected packages </summary>
        case "${str_package_manager}" in
            "apt" )
                local readonly str_option="--reinstall -o Dpkg::Options::=--force-confmiss"
                str_commands_to_execute="apt update && apt full-upgrade -y && apt install ${str_option} -y ${1}"
                ;;

            "dnf" )
                str_commands_to_execute="dnf upgrade && dnf install ${1}"
                ;;

            "pacman" )
                str_commands_to_execute="pacman -Syu && pacman -S ${1}"
                ;;

            "gentoo" )
                str_commands_to_execute="emerge -u @world && emerge ${1}"
                ;;

            "urpmi" )
                str_commands_to_execute="urpmi --auto-update && urpmi ${1}"
                ;;

            "yum" )
                str_commands_to_execute="yum update && yum install ${1}"
                ;;

            "zypper" )
                str_commands_to_execute="zypper refresh && zypper in ${1}"
                ;;

            * )
                echo -e "${str_output_fail}"
                return 1
                ;;
        esac

        echo "${str_output}"
        eval "${str_commands_to_execute}" || ( return 1 )
        AppendPassOrFail "${str_output}"
        return "${?}"
    }

    # <summary> Distro-agnostic, Uninstall a software package. </summary>
    # <param name="${1}"> string: the software package(s) </param>
    # <param name="${str_package_manager}"> string: the package manager </param>
    # <returns> exit code </returns>
    function UninstallPackage
    {
        CheckIfVarIsValid "${1}" || return "${?}"
        CheckIfVarIsValid "${str_package_manager}" || return "${?}"

        # <params>
        local str_commands_to_execute=""
        local readonly str_output="Uninstalling software packages..."
        local readonly str_output_fail="${var_prefix_fail}: Command '${str_package_manager}' is not supported."
        # </params>

        # <summary> Auto-update and auto-install selected packages </summary>
        case "${str_package_manager}" in
            "apt" )
                str_commands_to_execute="apt uninstall -y ${1}"
                ;;

            "dnf" )
                str_commands_to_execute="dnf remove ${1}"
                ;;

            "pacman" )
                str_commands_to_execute="pacman -R ${1}"
                ;;

            "gentoo" )
                str_commands_to_execute="emerge -Cv ${1}"
                ;;

            "urpmi" )
                str_commands_to_execute="urpme ${1}"
                ;;

            "yum" )
                str_commands_to_execute="yum remove ${1}"
                ;;

            "zypper" )
                str_commands_to_execute="zypper remove ${1}"
                ;;

            * )
                echo -e "${str_output_fail}"
                return 1
                ;;
        esac

        echo "${str_output}"
        eval "${str_commands_to_execute}" &> /dev/null || ( return 1 )
        AppendPassOrFail "${str_output}"
        return "${?}"
    }

    # <summary> Update or Clone repository given if it exists or not. </summary>
    # <param name="${1}"> string: the directory </param>
    # <param name="${2}"> string: the full repo name </param>
    # <param name="${3}"> string: the username </param>
    # <returns> exit code </returns>
    function UpdateOrCloneGitRepo
    {
        # <summary> Update existing GitHub repository. </summary>
        if CheckIfDirExists "${1}${2}"; then
            local var_command="git pull"
            cd "${1}${2}" && TryThisXTimesBeforeFail $( eval "${var_command}" )
            return "${?}"

        # <summary> Clone new GitHub repository. </summary>
        else
            if ReadInput "Clone repo '${2}'?"; then
                local var_command="git clone https://github.com/${2}"

                cd "${1}${3}" && TryThisXTimesBeforeFail $( eval "${var_command}" )
                return "${?}"
            fi
        fi
    }
# </code>

# <summary> Global parameters </summary>
# <params>
    # <summary> Getters and Setters </summary>
        declare -g bool_is_installed_systemd=false
        CheckIfCommandIsInstalled "systemd" &> /dev/null && bool_is_installed_systemd=true

        # declare -g bool_is_user_root=false
        # CheckIfUserIsRoot &> /dev/null && bool_is_user_root=true

        declare -gl str_package_manager=""
        CheckLinuxDistro &> /dev/null

    # <summary> Setters </summary>
        # <summary> Exit codes </summary>
        declare -gir int_code_partial_completion=255
        declare -gir int_code_skipped_operation=254
        declare -gir int_code_var_is_null=253
        declare -gir int_code_var_is_empty=252
        declare -gir int_code_var_is_not_bool=251
        declare -gir int_code_var_is_NAN=250
        declare -gir int_code_dir_is_null=249
        declare -gir int_code_file_is_null=248
        declare -gir int_code_file_is_not_executable=247
        declare -gir int_code_file_is_not_writable=246
        declare -gir int_code_file_is_not_readable=245
        declare -gir int_code_cmd_is_null=244
        declare -gi int_exit_code="${?}"

        # <summary>
        # Color coding
        # Reference URL: 'https://www.shellhacks.com/bash-colors'
        # </summary>
        declare -gr var_blinking_red='\033[0;31;5m'
        declare -gr var_blinking_yellow='\033[0;33;5m'
        declare -gr var_green='\033[0;32m'
        declare -gr var_red='\033[0;31m'
        declare -gr var_yellow='\033[0;33m'
        declare -gr var_reset_color='\033[0m'

        # <summary> Append output </summary>
        declare -gr var_prefix_error="${var_yellow}Error:${var_reset_color}"
        declare -gr var_prefix_fail="${var_red}Failure:${var_reset_color}"
        declare -gr var_prefix_pass="${var_green}Success:${var_reset_color}"
        declare -gr var_prefix_warn="${var_blinking_red}Warning:${var_reset_color}"
        declare -gr var_suffix_fail="${var_red}Failure${var_reset_color}"
        declare -gr var_suffix_maybe="${var_yellow}Incomplete${var_reset_color}"
        declare -gr var_suffix_pass="${var_green}Success${var_reset_color}"
        declare -gr var_suffix_skip="${var_yellow}Skipped${var_reset_color}"

        # <summary> Output statement </summary>
        declare -gr str_output_partial_completion="${var_prefix_warn} One or more operations failed."
        declare -gr str_output_please_wait="The following operation may take a moment. ${var_blinking_yellow}Please wait.${var_reset_color}"
        declare -gr str_output_var_is_not_valid="${var_prefix_error} Invalid input."
# </params>

# <summary> Business functions: Validation </summary>
# <code>
    function DetectExisting_VFIO
    {
        return 0
    }

    function IsEnabled_IOMMU
    {
        # <params>
        local readonly str_output="Checking if Virtualization is enabled/supported..."
        local readonly var_command='compgen -G "/sys/kernel/iommu_groups/*/devices/*"'
        # </params>

        if eval "${var_command}";
            echo -e "${str_suffix_pass}"
        then
            echo -e "${str_suffix_fail}"
            return 1
        fi

        return 0
    }
# </code>

# <summary> Business functions: Get IOMMU </summary>
# <code>
    # <summary> Parse IOMMU groups for all relevant information. If a parse fails, attempt again another way. If all parses fail, return error </summary>
    function Parse_IOMMU
    {
        function Parse_IOMMU_Main
        {
            function Parse_IOMMU_Are_Inequal_Lists_Sizes
            {
                local bool_are_inequal_lists=false
                [ "${#arr_IOMMU[@]}" -eq "${#arr_class[@]}" ] || bool_are_inequal_lists=true
                # [ "${#arr_IOMMU[@]}" -eq "${#arr_device_ID[@]}" ] || bool_are_inequal_lists=true
                [ "${#arr_IOMMU[@]}" -eq "${#arr_device_name[@]}" ] || bool_are_inequal_lists=true
                [ "${#arr_IOMMU[@]}" -eq "${#arr_driver[@]}" ] || bool_are_inequal_lists=true
                [ "${#arr_IOMMU[@]}" -eq "${#arr_hardware_ID[@]}" ] || bool_are_inequal_lists=true
                # [ "${#arr_IOMMU[@]}" -eq "${#arr_vendor_ID[@]}" ] || bool_are_inequal_lists=true
                [ "${#arr_IOMMU[@]}" -eq "${#arr_vendor_name[@]}" ] || bool_are_inequal_lists=true

                if "${bool_are_inequal_lists}"; then
                    echo -e "${str_output_lists_inequal}"
                    return 1
                fi

                return 0
            }

            function Parse_IOMMU_Are_Not_Empty_Lists
            {
                # <remarks> If any list is empty, fail. </remarks>
                local bool_is_empty_list=false
                CheckIfVarIsValid "${arr_class[@]}" &> /dev/null || bool_is_empty_list=true
                # CheckIfVarIsValid "${arr_device_ID[@]}" &> /dev/null || bool_is_empty_list=true
                CheckIfVarIsValid "${arr_device_name[@]}" &> /dev/null ||  bool_is_empty_list=true
                CheckIfVarIsValid "${arr_driver[@]}" &> /dev/null || bool_is_empty_list=true
                CheckIfVarIsValid "${arr_hardware_ID[@]}" &> /dev/null || bool_is_empty_list=true
                CheckIfVarIsValid "${arr_IOMMU[@]}" &> /dev/null || bool_is_empty_list=true
                # CheckIfVarIsValid "${arr_vendor_ID[@]}" &> /dev/null || bool_is_empty_list=true
                CheckIfVarIsValid "${arr_vendor_name[@]}" &> /dev/null || bool_is_empty_list=true

                if "${bool_is_empty_list}"; then
                    echo -e "${str_output_list_empty}"
                    return 1
                fi

                return 0
            }

            function Parse_IOMMU_Save_Lists
            {
                # <remarks> Save to lists each device's information. Lists should be of the same-size. </remarks>
                for str_slot_ID in "${arr_devices[@]}"; do
                    local str_class=$( eval "${var_parse_name_ID}" )
                    str_class=$( echo -e "${str_class}" | grep -i "Class:" | cut -d ':' -f 2 | grep -oP "^\t\K.*" )
                    # local str_device_ID=$( eval "${var_parse_all_ID}" | grep -i "Device:" | grep -Eiv "SDevice:|${str_slot_ID}" | awk '{print $2}' | uniq )
                    local str_device_ID=$( eval "${var_parse_quotes}" | cut -d '"' -f 6 | uniq )
                    local str_device_name=$( eval "${var_parse_name_ID}" | grep -i "Device:" | grep -Eiv "SDevice:|${str_slot_ID}" | cut -d ':' -f 2 | uniq | grep -oP "^\t\K.*" )
                    local str_driver=$( eval "${var_parse_all_ID}" | grep -i "Driver:" | awk '{print $2}' | uniq )
                    local str_IOMMU=$( eval "${var_parse_all_ID}"| grep -i "IOMMUGroup:" | awk '{print $2}' | uniq )
                    local str_vendor_name=$( eval "${var_parse_name_ID}" | grep -i "Vendor:" | grep -Eiv "SVendor:" | cut -d ':' -f 2 | uniq | grep -oP "^\t\K.*" )
                    # local str_vendor_ID=$( eval "${var_parse_all_ID}" | grep -i "Vendor:" | awk '{print $2}' | uniq )
                    local str_vendor_ID=$( eval "${var_parse_quotes}" | cut -d '"' -f 4 | uniq )

                    # <remarks> If system is setup for VFIO, exit. </remarks>
                    if [[ "${str_driver}" == "vfio-pci" ]]; then
                        echo -e "${str_output_is_setup_VFIO}"
                        return 1
                    fi

                    # <remarks> Match invalid input, and save as known null value. </remarks>
                    if ! CheckIfVarIsValid "${str_driver}" &> /dev/null; then
                        local str_driver="N/A"
                    fi

                    arr_class+=( "${str_class}" )
                    # arr_device_ID+=( "${str_device_ID}" )
                    arr_device_name+=( "${str_device_name}" )
                    arr_driver+=( "${str_driver}" )
                    arr_IOMMU+=( "${str_IOMMU}" )
                    arr_slot_ID+=( "${str_slot_ID}" )
                    # arr_vendor_ID+=( "${str_vendor_ID}" )
                    arr_vendor_name+=( "${str_vendor_name}" )
                    arr_hardware_ID+=( "${str_vendor_ID}:${str_device_ID}" )
                done

                return 0
            }

            function Parse_IOMMU_Set_Operation
            {
                # <remarks> Set commands for each parse type. </remarks>
                case "${var_opt}" in

                    # <remarks> If parsing file and file does not exist, recursive call to parse internet. </remarks>
                    "${str_opt_parse_file}" )
                        str_output="${str_output_parse_file}"
                        echo -e "${str_output}"

                        var_parse_all_ID+="${var_parse_args_file}"
                        var_parse_name_ID+="${var_parse_args_file}"
                        var_parse_slot_ID+="${var_parse_args_file}"
                        var_parse_quotes+="${var_parse_args_file}"

                        CheckIfFileExists "${str_file}" &> /dev/null
                        return "${?}"
                        ;;

                    # <remarks> If internet is not available, exit. </remarks>
                    "${str_opt_parse_internet}" )
                        str_output="${str_output_parse_internet}"
                        echo -e "${str_output}"

                        local readonly var_parse_all_ID+="${var_parse_args_online}"
                        local readonly var_parse_name_ID+="${var_parse_args_online}"
                        local readonly var_parse_slot_ID+="${var_parse_args_online}"
                        local readonly var_parse_quotes+="${var_parse_args_online}"

                        TestNetwork
                        return "${?}"
                        ;;

                    "${str_opt_parse_local}" | * )
                        str_output="${str_output_parse_local}"
                        echo -e "${str_output}"
                        ;;
                esac

                return 0
            }

            # <params>
                # <remarks> Save input params </remarks>
                var_opt="${1}"

                # <remarks> Output statements </remarks>
                local readonly str_output_lists_inequal="${var_prefix_error} System PCI lists' sizes are inequal."
                local readonly str_output_list_empty="${var_prefix_error} One or more system PCI lists are empty."
                local readonly str_output_parse_file="Parsing PCI from file..."
                local readonly str_output_parse_internet="Parsing PCI devices from Internet database..."
                local readonly str_output_parse_local="Parsing PCI devices from local database..."
                local readonly str_output_is_setup_VFIO="${var_prefix_error} Found existing VFIO setup."

                # <remarks> Declare lists </remarks>
                declare -ag arr_class arr_device_ID arr_device_name arr_driver arr_hardware_ID arr_IOMMU arr_slot_ID arr_vendor_ID arr_vendor_name

                # <remarks> Set commands </remarks>
                local readonly var_parse='lspci -k -mm'
                local readonly var_parse_args_file='-F "${str_file}"'
                local readonly var_parse_args_online='-q'
                local readonly var_parse_args_nums='-n'
                local readonly var_parse_args_slot_ID='-s ${str_slot_ID}'
                local readonly var_parse_args_verbose='-v'
                local readonly var_parse_to_file='lspci -x >> "${str_file}"'

                local var_parse_all_ID="${var_parse} ${var_parse_args_nums} ${var_parse_args_verbose} ${var_parse_args_slot_ID}"
                local var_parse_name_ID="${var_parse} ${var_parse_args_verbose} ${var_parse_args_slot_ID}"
                local var_parse_slot_ID="${var_parse}"
                local var_parse_quotes="${var_parse} ${var_parse_args_nums}"
            # </params>

            # <remarks> Set commands for each parse type. </remarks>
            Parse_IOMMU_Set_Operation || return "${?}"

            # <remarks> Get all devices from system. </remarks>
            declare -a arr_devices=( $( eval ${var_parse_slot_ID} | awk '{print $1}' ) )
            Parse_IOMMU_Save_Lists || return "${?}"

            Parse_IOMMU_Are_Not_Empty_Lists || return "${?}"
            Parse_IOMMU_Are_Inequal_Lists_Sizes || return "${?}"

            # <remarks> Save output to file. </remarks>
            if [[ "${?}" -eq 0 && "${var_opt}" != "${str_opt_parse_file}" ]]; then
                CheckIfFileExists "${str_file}" &> /dev/null && eval "${var_parse_to_file}"
            fi

            return 0
        }

        # <params>
            # <remarks> Set parse options </remarks>
            local readonly str_opt_parse_file="FILE"
            local readonly str_opt_parse_internet="DNS"
            local readonly str_opt_parse_local="LOCAL"

            # <remarks> Save input params </remarks>
            local var_opt="${1}"
            local readonly str_file="${2}"
        # </params>

        # <remarks> If an operation fails, try another. </remarks>
        case "${var_opt}" in
            "${str_opt_parse_internet}" )
                Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                ;;

            "${str_opt_parse_file}" )
                Parse_IOMMU_Main "${str_opt_parse_file}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                ;;

            "${str_opt_parse_local}" | * )
                Parse_IOMMU_Main "${str_opt_parse_local}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_file}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                ;;
        esac

        AppendPassOrFail "${str_output}"

        # <remarks> Save output. </remarks>
        readonly arr_class arr_device_ID arr_device_name arr_driver arr_hardware_ID arr_IOMMU arr_slot_ID arr_vendor_ID arr_vendor_name

        return "${int_exit_code}"
    }

    function Select_IOMMU
    {
        function Select_IOMMU_Match_IOMMU_AndClass
        {
            # <params>
            local readonly str_class="${arr_class[$int_key]}"
            # local readonly str_device_ID="${arr_device_ID[$int_key]}"
            local readonly str_device_name="${arr_device_name[$int_key]}"
            local readonly str_driver="${arr_driver[$int_key]}"
            local readonly str_hardware_ID="${arr_hardware_ID[$int_key]}"
            local readonly str_slot_ID="${arr_slot_ID[$int_key]}"
            # local readonly str_vendor_ID="${arr_vendor_ID[$int_key]}"
            local readonly str_vendor_name="${arr_vendor_name[$int_key]}"

            local readonly str_domain_ID=$( echo "${str_slot_ID}" | cut -d ':' -f 1 )

            # <remarks> Regex: check if value is decimal or hexadecimal and greater than zero </remarks>
            local readonly str_regex='[a-fA-F1-9]'

            # <remarks> Output statement </remarks>
            declare -ar arr_output=(
                "Slot ID:\t'${str_slot_ID}'"
                "Vendor name:\t'${str_vendor_name}'"
                "Device name:\t'${str_device_name}'"
                "Class/Type:\t'${str_class}'"
                # "Hardware ID:\t'${str_hardware_ID}'"
                # "Vendor ID:\t'${str_vendor_ID}'"
                # "Device ID:\t'${str_device_ID}'"
                "Kernel driver:\t'${str_driver}'"
            )
            # </params>

            # <remarks> Match IOMMU group </remarks>
            if [[ "${int_IOMMU}" -eq "${int_this_IOMMU_ID}" ]]; then

                # <remarks> External PCI devices have domain IDs of '01' or greater. </remarks>
                if [[ "${str_domain_ID}" =~ ${str_regex} ]]; then
                    bool_IOMMU_has_external_domain=true
                fi

                local str_class=$( echo "${arr_class[$int_key]}" | tr '[:upper:]' '[:lower:]' )
                PrintArray

                # <remarks> Match Class </remarks>
                case "${str_class}" in
                    "graphics" | "vga" | "video" )
                        bool_IOMMU_has_VGA=true
                        # bool_IOMMU_VFIO_PCI=true
                        ;;

                    "usb" )
                        bool_IOMMU_has_USB=true
                        bool_IOMMU_PCI_STUB=true
                        ;;
                esac
            fi

            return 0
        }

        function Select_IOMMU_Prompt
        {
            # <params>
            local readonly str_output_do_select="Select IOMMU group '${int_this_IOMMU_ID}'?"
            local readonly str_output_skip_select="Skipped IOMMU group '${int_this_IOMMU_ID}'."
            # </params>

            # <remarks> Append to list a valid array or empty value. </remarks>
            if "${bool_IOMMU_has_external_domain}" && ReadInput "${str_output_do_select}"; then
                if "${bool_IOMMU_has_USB}"; then
                    arr_IOMMU_PCI_STUB+=( "${int_this_IOMMU_ID}" )
                else
                    arr_IOMMU_PCI_STUB+=( "" )
                fi

                if "${bool_IOMMU_has_VGA}"; then
                    arr_IOMMU_VFIO_PCI+=( "" )
                    arr_IOMMU_VFIO_PCI_with_VGA+=( "${int_this_IOMMU_ID}" )
                else
                    arr_IOMMU_VFIO_PCI+=( "${int_this_IOMMU_ID}" )
                    arr_IOMMU_VFIO_PCI_with_VGA+=( "" )
                fi
            else
                arr_IOMMU_VFIO_PCI+=( "" )
                arr_IOMMU_PCI_STUB+=( "" )
                arr_IOMMU_VFIO_PCI_with_VGA+=( "" )
                echo -e "${str_output_skip_select}"
            fi

            return 0
        }

        # <params>
        local readonly str_output="Reviewing IOMMU groups..."
        local readonly int_IOMMU_max=$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )
        local readonly var_get_IOMMU='seq 0 "${int_IOMMU_max}"'
        declare -a arr_IOMMU_PCI_STUB arr_IOMMU_VFIO_PCI arr_IOMMU_VFIO_PCI_with_VGA
        declare -ar arr_this_IOMMU=( $( eval "${var_get_IOMMU}" ) )
        # </params>

        echo -e "${str_output}"

        for int_this_IOMMU_ID in "${arr_this_IOMMU[@]}"; do
            local bool_IOMMU_has_external_domain=false
            local bool_IOMMU_PCI_STUB=false
            # local bool_IOMMU_VFIO_PCI=false
            local bool_IOMMU_has_USB=false
            local bool_IOMMU_has_VGA=false

            for int_key in ${!arr_IOMMU[@]}; do
                declare -i int_IOMMU="${arr_IOMMU[$int_key]}"
                Select_IOMMU_Match_IOMMU_AndClass
            done

            Select_IOMMU_Prompt
        done

        # TOOD: create a function that takes in a string, which is the name of another parameter (like a pointer) and perform validation given the var type (check prefix var, str, int, arr, etc.)

        # <remarks> Check if list is empty </remarks>
        declare -a arr=( "${arr_IOMMU_VFIO_PCI[@]}" )
        CheckIfArrayIsEmpty

        AppendPassOrFail "${str_output}"
        echo
        return "${int_exit_code}"
    }
# </code>

# <summary> Business functions: Main setup </summary>
# <code>
    function Multiboot_VFIO
    {
        # <params>
        local readonly str_file1="/etc/default/grub"
        local readonly str_file2="/etc/grub.d/proxifiedScripts/custom"
        local readonly str_file1_backup="etc_default_grub"
        local readonly str_file2_backup="etc_grub.d_proxifiedScripts_custom"
        # </params>

        GoToScriptDir && cd "${str_files_dir}"

        if ! CheckIfFileExists "${str_file1_backup}" || CheckIfFileExists "${str_file2_backup}"; then
            return "$?"
        fi


    }

    function Static_VFIO
    {
        # <params>
        declare -a arr_file1_contents arr_file2_contents arr_file3_contents arr_file4_contents arr_file5_contents
        local readonly str_file1="/etc/default/grub"
        local readonly str_file2="/etc/initramfs-tools/modules"
        local readonly str_file3="/etc/modprobe.d/pci-blacklists.conf"
        local readonly str_file4="/etc/modprobe.d/vfio.conf"
        local readonly str_file5="/etc/modules"
        local readonly str_file1_backup="etc_default_grub"
        local readonly str_file2_backup="etc_initramfs-tools_modules"
        local readonly str_file3_backup="etc_modprobe.d_pci-blacklists.conf"
        local readonly str_file4_backup="etc_modprobe.d_vfio.conf"
        local readonly str_file5_backup="etc_modules"


        local readonly str_GRUB_driver_blacklist="modprobe.blacklist=${str_driverListForVFIO}"
        local readonly str_GRUB_HW_ID_pci-stub="pci-stub.ids=${str_driverListForSTUB}"
        local readonly str_GRUB_HW_ID_vfio-pci="pci-stub.ids=${str_driverListForSTUB}"
        # </params>

        # <remarks> Check if backup files exist. </remarks>
        GoToScriptDir && cd "${str_files_dir}"

        if ! CheckIfFileExists "${str_file1_backup}" || CheckIfFileExists "${str_file2_backup}" || CheckIfFileExists "${str_file3_backup}" || CheckIfFileExists "${str_file4_backup}"|| CheckIfFileExists "${str_file5_backup}"; then
            return "${?}"
        fi

        # <remarks> Backup existing system files. </remarks>
        # NOTE: will a conflict exist should backup files exist in given directories (example: modprobe.d) and not others (ex: grub)
        CreateBackupFile "${str_file1_backup}"
        CreateBackupFile "${str_file2_backup}"
        CreateBackupFile "${str_file3_backup}"
        CreateBackupFile "${str_file4_backup}"
        CreateBackupFile "${str_file5_backup}"

        # <remarks> GRUB </remarks>
        arr_file1_contents=(
            "${str_GRUB_Allocate_CPU}"
            "${str_GRUB_hugepages}"
            "modprobe.blacklist=${str_driverListForVFIO}"
            "pci-stub.ids=${str_driverListForSTUB}"
            "vfio_pci.ids=${str_HWID_list_forVFIO}"
        )

        # <remarks> Modules </remarks>


        # <remarks> Modprobe </remarks>



        return 0
    }

    function Setup_VFIO
    {
        # <params>

        # </params>

        # diff between static and multiboot => static: all IOMMU for VFIO with PCI STUB devices will be binded to VFIO PCI driver? append only to GRUB and system files.
        # multiboot: PCI STUB devices will use PCI STUB driver? append only GRUB and multiple GRUB entries

        return 0
    }

    function UpdateExisting_VFIO
    {
        return 0
    }
# </code>

# <summary> Business functions: Pre/Post setup </summary>
# <code>
    # <params>
    declare -g bool_is_setup_evdev=false
    declare -g bool_is_setup_hugepages=false
    # </params>

    # <summary> Add user to necessary user groups. </summary>
    function AddUserToGroups
    {
        # <params>
        local readonly str_output="Adding user to groups..."
        local readonly var_get_first_valid_user='getent passwd {1000..60000} | cut -d ":" -f 1'
        local readonly str_username=$( eval "${var_get_first_valid_user}" )
        # </params>

        # <remarks> Add user(s) to groups. </remarks>
        echo -e "${str_output}"
        adduser "${str_username}" "input" || return 1
        adduser "${str_username}" "libvirt" || return 1
        AppendPassOrFail "${str_output}"
        echo
        return 0
    }

    # <summary> isolcpus: Ask user to allocate host CPU cores (and/or threads), to reduce host overhead, and improve both host and virtual machine performance. </summary
    function Allocate_CPU
    {
        # <params>
        local readonly str_output="Allocating CPU threads..."
        local readonly var_get_all_cores='seq 0 $(( ${int_total_cores} - 1 ))'
        local readonly var_get_total_threads='cat /proc/cpuinfo | grep "siblings" | uniq | grep -o "[0-9]\+"'
        local readonly var_get_total_cores='cat /proc/cpuinfo | grep "cpu cores" | uniq | grep -o "[0-9]\+"'
        declare -ir int_total_cores=$( eval "${var_get_total_cores}" )
        declare -ir int_total_threads=$( eval "${var_get_total_threads}" )
        # </params>

        echo -e "${str_output}"

        # <summary> Set maximum number of cores allocated to host machine. </summary>
            # <params>
            declare -ar arr_all_cores=( $( eval "${var_get_all_cores}" ) )
            declare -i int_host_cores=1
            # </params>

            # <remarks> quad-core or greater CPU </remarks>
            if [[ "${int_total_cores}" -ge 4 ]]; then
                readonly int_host_cores=2

            # <remarks> double-core/triple-core CPU </remarks>
            elif [[ "${int_total_cores}" -le 3 && "${int_total_cores}" -ge 2 ]]; then
                readonly int_host_cores

            # <remarks> If single-core CPU, fail. </remarks>
            else
                readonly int_host_cores
                false
                AppendPassOrFail "${str_output}"
                return "${int_exit_code}"
            fi

        # <summary> Get thread sets, for host and virtual machines. </summary>
            # <params>
            local readonly var_get_host_cores='seq 0 $(( ${int_host_cores} - 1 ))'
            local readonly var_get_SMT_factors='seq 0 $(( ${int_SMT_factor} - 1 ))'
            local readonly var_get_thread='$(( int_core + ( int_SMT_factor * int_total_cores ) ))'
            local readonly var_get_virt_cores='seq ${int_host_cores} $(( ${int_total_cores} - 1 ))'

            declare -ar arr_host_cores=( $( eval "${var_get_host_cores}" ) )
            declare -a arr_host_threads=()
            declare -ar arr_virt_cores=( $( eval "${var_get_virt_cores}" ) )
            declare -a arr_virt_threads=()
            declare -i int_SMT_factor=$(( "${int_total_threads}" / "${int_total_cores}" ))
            declare -a arr_SMT_factors=( $( eval "${var_get_SMT_factors}" ) )

            declare -g str_host_thread_sets
            declare -g str_virt_thread_sets
            # </params>

            function GetThreadByCoreAnd_SMT
            {
                int_thread=$(( int_core + ( int_SMT_factor * int_total_cores ) ))
            }

            for int_SMT_factor in "${arr_SMT_factors[@]}"; do
                # <remarks> Reset params </remarks>
                declare -a arr_host_threads_sets=()
                declare -a arr_virt_threads_sets=()
                declare -i int_thread

                # <remarks> Find thread sets for host machine. </remarks>
                for int_core in "${arr_host_cores[@]}"; do
                    GetThreadByCoreAnd_SMT
                    arr_host_threads+=( "${int_thread}" )
                    arr_host_threads_sets+=( "${int_thread}" )
                done

                # <remarks> Find thread sets for virtual machines. </remarks>
                for int_core in "${arr_virt_cores[@]}"; do
                    GetThreadByCoreAnd_SMT
                    arr_virt_threads+=( "${int_thread}" )
                    arr_virt_threads_sets+=( "${int_thread}" )
                done

                # <remarks> Save thread sets to delimited list. </remarks>
                declare -i int_set_first_thread="${arr_host_threads_sets[0]}"
                declare -i int_set_last_thread="${arr_host_threads_sets[-1]}"
                local str_thread_set="${int_set_first_thread}"

                if [[ "${int_set_first_thread}" -ne "${int_set_last_thread}" ]]; then
                    local str_thread_set="${int_set_first_thread}-${int_set_last_thread}"
                fi

                str_host_thread_sets+="${str_thread_set},"

                declare -i int_set_first_thread="${arr_virt_threads_sets[0]}"
                declare -i int_set_last_thread="${arr_virt_threads_sets[-1]}"
                local str_thread_set="${int_set_first_thread}"

                if [[ "${int_set_first_thread}" -ne "${int_set_last_thread}" ]]; then
                    local str_thread_set="${int_set_first_thread}-${int_set_last_thread}"
                fi

                str_virt_thread_sets+="${str_thread_set},"
            done

            # <remarks> Truncate last delimiter. </remarks>
            if [[ ${str_host_thread_sets: -1} == "," ]]; then
                str_host_thread_sets=${str_host_thread_sets::-1}
            fi

            # <remarks> Ditto. </remarks>
            if [[ ${str_virt_thread_sets: -1} == "," ]]; then
                str_virt_thread_sets=${str_virt_thread_sets::-1}
            fi

            # <remarks> Save output </remarks>
            readonly str_host_thread_sets str_virt_thread_sets

        # <summary> Find CPU mask. </summary>
            # <remarks>
            # save output to string for cpuset and cpumask
            # example:
            #   host 0-1,8-9
            #   virt 2-7,10-15
            #
            # information
            # cores     bit masks       mask
            # 0-7       0b11111111      FF      # total cores
            # 0,4       0b00010001      11      # host cores
            #
            # 0-11      0b111111111111  FFF     # total cores
            # 0-1,6-7   0b000011000011  C3      # host cores
            #
            # </remarks>

            # <params>
            local readonly var_get_hexadecimal_mask_from_decimal='echo "obase=16; ${int_thread_decimal}" | bc'
            declare -i int_host_threads_hexadecimal_mask=0
            declare -i int_total_threads_hexadecimal_mask=0
            # </params>

            # <remarks> Add each decimal mask to sum. </remarks>
            for int_thread in "${arr_host_threads[@]}"; do
                declare -i int_thread_decimal=$(( 2 ** ${int_thread} ))
                declare -i int_thread_hexadecimal_mask=$( eval "${var_get_hexadecimal_mask_from_decimal}" )
                int_host_threads_hexadecimal_mask+="${int_thread_hexadecimal_mask}"
            done

            for int_thread in "${arr_total[@]}"; do
                declare -i int_thread_decimal=$(( 2 ** ${int_thread} ))
                declare -i int_thread_hexadecimal_mask=$( eval "${var_get_hexadecimal_mask_from_decimal}" )
                int_host_threads_hexadecimal_mask+="${int_thread_hexadecimal_mask}"
            done

            # <remarks> Save changes, convert hexadecimal mask into hexadecimal. </remarks>
            readonly int_host_threads_hexadecimal_mask
            declare -gr str_host_threads_hexadecimal=$( printf '%x\n' $int_host_threads_hexadecimal_mask )
            declare -ir int_total_threads_hexadecimal_mask=$(( ( 2 ** ${int_total_threads} ) - 1 ))
            declare -gr str_total_threads_hexadecimal=$( printf '%x\n' $int_total_threads_hexadecimal_mask )

        declare -a arr_output=(
            "Allocated to Host\t${str_host_thread_sets}"
            "Allocated to guest:\t${str_virt_thread_sets}"
        )

        PrintArray
        echo

        # <remarks> Save changes. </remarks>
        declare -gr str_GRUB_Allocate_CPU="isolcpus=${str_virt_thread_sets} nohz_full=${str_virt_thread_sets} rcu_nocbs=${str_virt_thread_sets}"
        AppendPassOrFail "${str_output}"
        echo
        return 0
    }

    # <summary> Hugepages: Ask user to allocate host memory (RAM) to 'hugepages', to eliminate the need to defragement memory, to reduce host overhead, and to improve both host and virtual machine performance. </summary
    function Allocate_RAM
    {
        # <params>
        declare -ar arr_choices=(
            "2M"
            "1G"
        )

        declare -I bool_is_setup_hugepages
        declare -gi int_huge_page_count=0
        declare -gi int_huge_page_kbit_size=0
        declare -gi int_huge_page_max_kbit_size=0
        declare -gir int_huge_page_min_kbit_size=4194304
        declare -gi int_huge_page_max=0
        declare -gi int_huge_page_min=0
        declare -g str_huge_page_byte_prefix=""
        declare -g str_GRUB_hugepages=""
        declare -g str_hugepages_QEMU=""

        local readonly str_output1="Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n"
        local readonly str_output2="Setup Hugepages?"
        local readonly str_output3="Enter size of Hugepages (bytes):"
        local readonly var_get_host_max_mem='cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1'
        # </params>

        # <remarks> Ask user to proceed. </remarks>
        echo -e "${str_output1}"
        ReadInput "${str_output2}" || return "${?}"
        ReadMultipleChoiceIgnoreCase "${str_output3}" "${arr_choices[@]}" || return "${?}"
        var_input=""
        str_huge_page_byte_prefix="${var_input}"
        int_huge_page_max_kbit_size=$( eval "${var_get_host_max_mem}" )

        # <remarks> Validate hugepage size and byte-size. </remarks>
        case "${str_huge_page_byte_prefix}" in
            "${arr_choices[0]}" )
                readonly int_huge_page_kbit_size=2048
                readonly int_huge_page_min=2
                ;;
            "${arr_choices[1]}" )
                readonly int_huge_page_kbit_size=1048576
                readonly int_huge_page_min=1
                ;;
            * )
                return "${?}"
                ;;
        esac

        # <remarks> Get values. </remarks>
        readonly int_huge_page_max=$(( $int_huge_page_min_kbit_size - $int_huge_page_min_kbit_size ))
        readonly int_HugePageMax=$(( $int_huge_page_max / $int_huge_page_kbit_size ))
        local readonly str_output4="Enter number of Hugepages (n * ${str_huge_page_byte_prefix})"

        # <remarks> Ask user for preferred amount. </remarks>
        ReadInputFromRangeOfTwoNums "${str_output4}" "${int_huge_page_min}" "${int_huge_page_max}" || return "${?}"
        readonly int_huge_page_count="${var_input}"

        # <remarks> Save changes. </remarks>
        readonly str_GRUB_hugepages="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
        bool_is_setup_hugepages=true
        return 0
    }

    # <summary> Ask user to setup audio loopback from the host's Line-in to active audio output. Useful for virtual machines with sound-cards (example: Creative SoundBlaster). </summary>
    function HostAudioLineIn
    {
        return 0
    }

    function LibvirtHooks
    {
        return 0
    }

    # <summary> zramswap: Ask user to setup a swap partition in host memory, to reduce swapiness to existing host swap partition(s)/file(s), and reduce chances of memory exhaustion as host over-allocates memory. </summary>
    function RAM_Swapfile
    {
        return 0
    }

    # <summary> Evdev: Ask user to setup a virtual Keyboard-Video-Mouse swich (excluding the Video). Will allow a user to swap between active virtual machines and host, with the use of a pre-defined macro (example: 'L-CTRL' + 'R-CTRL'). </summary>
    function Virtual_KVM
    {
        # <params>
        declare -ga arr_event_devices=()
        declare -ga arr_input_devices=()

        declare -I bool_is_setup_evdev
        local readonly str_output1="Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
        local readonly str_output2="Setup Evdev?"

        local readonly var_get_event_devices='ls -l /dev/input/by-id | cut -d "/" -f2 | grep -v "total 0"'
        local readonly var_get_input_devices='ls /dev/input/by-id'
        # </params>

        # <remarks> Ask user to proceed. </remarks>
        echo -e "${str_output1}"
        ReadInput "${str_output2}" || return "${?}"

        # <remarks> Get all devices for Evdev. </remarks>
        readonly arr_event_devices=( $( eval "${var_get_event_devices}") )
        readonly arr_input_devices=( $( eval "${var_get_input_devices}") )

        # <remarks> Early-exit. </remarks>
        if ! CheckIfVarIsValid "${arr_event_devices[@]}" && ! CheckIfVarIsValid "${var_get_input_devices[@]}"; then
            return 1
        fi

        bool_is_setup_evdev=true
        return 0
    }

    # <summary> libvirt-qemu: Append necessary changes to QEMU system file, including user groups, Evdev, Hugepages, and NVRAM (for UEFI VMs). </summary>
    function Modify_QEMU
    {
        # <params>
        declare -a arr_file1_evdev_cgroups=()
        declare -ar arr_file1_default_cgroups=(
            "        \"/dev/null\", \"/dev/full\", \"/dev/zero\","
            "        \"/dev/random\", \"/dev/urandom\","
            "        \"/dev/ptmx\", \"/dev/kvm\","
            "        \"/dev/rtc\", \"/dev/hpet\""
        )

        declare -I bool_is_setup_evdev bool_is_setup_hugepages
        local readonly str_daemon1="libvirtd"
        local readonly str_daemon1_packages="qemu"
        local readonly str_file1="/etc/libvirt/qemu.conf"
        local readonly str_file1_backup="./files/etc_libvirt_qemu.conf"
        local readonly var_set_event_device='"        \"/dev/input/by-id/${str_event_device}\",'
        # </params>

        # <remarks> Backup system file and grab clean file from repository. </remarks>
        CreateBackupFile "${str_file1}"
        GoToScriptDir || return "${?}"
        CheckIfFileExists "${str_file1_backup}" || return "${?}"
        cp "${str_file1_backup}" "${str_file1}" || return 1

        # <remarks> Get Event devices. </remarks>
        if "${bool_is_setup_evdev}"; then
            for str_event_device in "${arr_event_devices[@]}"; do
                arr_file1_evdev_cgroups+=( $( eval "${var_set_event_device}" ) )
            done

            for str_event_device in "${arr_event_devices[@]}"; do
                arr_file1_evdev_cgroups+=( $( eval "${var_set_event_device}" ) )
            done
        fi

        # <remarks> Save changes. </remarks>
        readonly arr_file1_evdev_cgroups

        # <remarks> Begin append. </remarks>
        arr_file1_contents=(
            "#"
            "# Generated by '${str_full_repo_name}'"
            "#"
            "# WARNING: Any modifications to this file will be modified by"
            "'${str_repo_name}'"
            "#"
            "# Run 'systemctl restart ${str_daemon1}.service' to update."
        )

        # <remarks> Adds or omits specific user to use Evdev. </remarks>
        local readonly str_output4="Adding user..."

        if CheckIfVarIsValid "${str_user_name}" &> /dev/null; then
            arr_file1_contents+=(
                "#"
                "### User permissions ###"
                "        user = \"${str_user_name}\""
                "        group = \"user\""
                "#"
            )

            AppendPassOrFail "${str_output4}"
        else
            arr_file1_contents+=(
                "#"
                "### User permissions ###"
                "#         user = \"user\""
                "#         group = \"user\""
                "#"
            )

            AppendPassOrFail "${str_output4}"
        fi

        # <remarks> Adds or omits validation for Hugepages. </remarks>
        local readonly str_output5="Adding Hugepages..."

        if "${bool_is_setup_hugepages}"; then
            arr_file1_contents+=(
                "#"
                "### Hugepages ###"
                "        hugetlbfs_mount = \"/dev/hugepages\""
                "#"
            )

            AppendPassOrFail "${str_output5}"
        else
            arr_file1_contents+=(
                "#"
                "### Hugepages ###"
                "#         hugetlbfs_mount = \"/dev/hugepages\""
                "#"
            )

            AppendPassOrFail "${str_output5}"
        fi

        # <remarks> Adds or omits Event devices. </remarks>
        local readonly str_output6="Adding Hugepages..."

        if CheckIfVarIsValid "${arr_file1_evdev_cgroups[@]}" &> /dev/null; then
            arr_file1_contents+=(
                "#"
                "### Devices ###"
                "# cgroup_device_acl = ["
                "${arr_file1_evdev_cgroups[@]}"
                "${arr_file1_default_cgroups[@]}"
                "        ]"
                "#"
            )

            AppendPassOrFail "${str_output6}"
        else
            arr_file1_contents+=(
                "#"
                "### Devices ###"
                "# cgroup_device_acl = ["
                "${arr_file1_default_cgroups[@]}"
                "        ]"
                "#"
            )

            AppendPassOrFail "${str_output6}"
        fi

        # <remarks> Adds NVRAM for EFI kernels in UEFI virtual machines. </remarks>
        arr_file1_contents+=(
            "nvram = ["
            "        \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\","
            "        \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\","
            "        \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\","
            "        \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\""
            "]"
        )

        # <remarks> Save changes. </remarks>
        readonly arr_file1_contents
        declare -a arr_file=( "${arr_file1_contents[@]}" )
        WriteFile "${str_file1}" || return "${?}"

        # <remarks> Check if daemon exists and restart it. </remarks>
        CheckIfPackageExists "${str_daemon1_package}" || return "${?}"
        CheckIfDaemonIsActiveOrNot "${str_daemon1}" || ( systemctl enable "${str_daemon1}" || return 1 )
        systemctl restart "${str_daemon1}" || return 1
        return 0
    }

    # <summary> LookingGlass: Ask user to setup direct-memory-access of video framebuffer from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
    function VirtualVideoCapture
    {
        return 0
    }

    # <summary> Scream: Ask user to setup audio loopback from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
    function VirtualAudioCapture
    {
        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    # TODO: debug and fix usage (options and arguments)

    function PrintUsage
    {
        # <params>
        IFS=$'\n'
        local readonly var_get_script_name='basename "${0}"'
        local readonly str_script_name=$( eval "${var_get_script_name}" )
        local readonly str_opt_full_setup="-f, --full\texecute pre-setup, VFIO setup, and post-setup"
        local readonly str_opt_help="-h, --help\tdisplay this help and exit"
        local readonly str_opt_multiboot_VFIO_setup="-m, --multiboot\texecute preferred VFIO setup: modify GRUB boot options only (excluding GRUB file and system files)"
        local readonly str_opt_post_setup="-P, --post\texecute post-setup (LookingGlass, Scream)"
        local readonly str_opt_pre_setup="-p, --pre\texecute pre-setup (allocate CPU, hugepages, zramswap, Evdev)"
        local readonly str_opt_static_VFIO_setup="-s, --static\texecute preferred VFIO setup: modify GRUB file and system files only"
        local readonly str_opt_update_VFIO_setup="-u, --update\tdetect existing VFIO setup, execute new VFIO setup, and apply changes"
        local readonly str_arg_silent="-S, --silent\tdo not prompt before execution"
        local readonly str_arg_file="-F, --file\tparse PCI from file"
        local readonly str_arg_online="-O, --online\tparse PCI from internet"

        declare -ar arr_usage=(
            "Usage:\t${str_script_name} [OPTION] [ARGUMENTS]"
            "\tor ${str_script_name} [OPTION] -S"
            "\tor ${str_script_name} [d/m/s/u] -F [FILE_NAME]"
            "\tor ${str_script_name} [d/m/s/u] -o"
            "\nRequired variables:"
            "\t${str_script_name}"
            "\nOptional variables:"
            "\t${str_opt_help}"
            "\t${str_opt_multiboot_VFIO_setup}"
            "\t${str_opt_static_VFIO_setup}"
            "\t${str_opt_update_VFIO_setup}"
            "\t${str_opt_post_setup}"
            "\t${str_opt_pre_setup}"
            "\t${str_opt_full_setup}"
            "\nArguments:"
            "\t${str_arg_silent}"
            "\t${str_arg_file}"
            "\t${str_arg_online}"
        )
        # </params>

        # <remarks> Display usage. </remarks>
        for str_line in ${arr_usage[@]}; do
            echo -e "${str_line}"
        done

        return 0
    }

    function GetUsage
    {
        # <params>

        # NOTE: it appears declaring inherited vars doesn't work here. As I have used this in other areas, test it for validity.
        # declare -I bool_opt_multiboot_VFIO_setup bool_opt_any_VFIO_setup bool_opt_help bool_opt_post_setup bool_opt_pre_setup bool_opt_static_VFIO_setup bool_opt_update_VFIO_setup bool_arg_silent

        declare -gr arr_usage_opt=(
            "-h"
            "--help"
            "-m"
            "--multiboot"
            "-f"
            "--full"
            "-P"
            "--post"
            "-p"
            "--pre"
            "-s"
            "--static"
            "-u"
            "--update"
        )

        declare -gr arr_usage_args=(
            "-S"
            "--silent"
            "-F"
            "--file"
            "-o"
            "--online"
        )

        if CheckIfVarIsValid "${1}" &> /dev/null; then
            case "${1}" in
                "${arr_usage_opt[0]}" | "${arr_usage_opt[1]}" )
                    bool_opt_help=true
                    ;;
                "${arr_usage_opt[2]}" | "${arr_usage_opt[3]}" )
                    bool_opt_multiboot_VFIO_setup=true
                    ;;
                "${arr_usage_opt[4]}" | "${arr_usage_opt[5]}" )
                    bool_opt_any_VFIO_setup=true
                    bool_opt_post_setup=true
                    bool_opt_pre_setup=true
                    ;;
                "${arr_usage_opt[6]}" | "${arr_usage_opt[7]}" )
                    bool_opt_post_setup=true
                    ;;
                "${arr_usage_opt[8]}" | "${arr_usage_opt[9]}" )
                    bool_opt_pre_setup=true
                    ;;
                "${arr_usage_opt[10]}" | "${arr_usage_opt[11]}" )
                    bool_opt_static_VFIO_setup=true
                    ;;
                "${arr_usage_opt[12]}" | "${arr_usage_opt[13]}" )
                    bool_opt_update_VFIO_setup=true
                    ;;
                "${arr_usage_args[0]}" | "${arr_usage_args[1]}" )
                    bool_arg_silent=true
                    ;;
                * )
                    bool_opt_help=true
                    echo -e "${str_output_var_is_not_valid}"
                    return 1
                    ;;
            esac
        else
            bool_opt_any_VFIO_setup=true
        fi

        case "${2}" in
            "${arr_usage_args[0]}" | "${arr_usage_args[1]}" )
                bool_arg_silent=true
                ;;

            "${arr_usage_args[2]}" | "${arr_usage_args[3]}" )
                bool_arg_parse_file=true
                ;;

            "${arr_usage_args[4]}" | "${arr_usage_args[5]}" )
                bool_arg_parse_online=true
                ;;
        esac
        # </params>

        return 0
    }

    # <params>
    readonly var_input1="${1}"
    readonly var_input2="${2}"
    readonly var_input3="${3}"

    declare -g bool_opt_multiboot_VFIO_setup=false
    declare -g bool_opt_any_VFIO_setup=false
    declare -g bool_opt_help=false
    declare -g bool_opt_post_setup=false
    declare -g bool_opt_pre_setup=false
    declare -g bool_opt_static_VFIO_setup=false
    declare -g bool_opt_update_VFIO_setup=false
    declare -g bool_arg_silent=false
    declare -g bool_arg_parse_file=false
    declare -g bool_arg_parse_online=false

    declare -gr str_repo_name="deploy-VFIO-setup"
    declare -gr str_full_repo_name="portellam/${str_repo_name}"
    GoToScriptDir; declare -gr str_files_dir="$( find . -name files | uniq | head -n1 )/"
    declare -g bool_is_connected_to_Internet=false
    # </params>

    CheckIfUserIsRoot || exit "${?}"
    GetUsage "${var_input1}" "${var_input2}"
    SaveExitCode

    # <remarks> Output usage </remarks>
    if "${bool_opt_help}"; then
        PrintUsage
        exit "${int_exit_code}"
    fi

    # <remarks> Get and ask user to select IOMMU groups. </remarks>
    if "${bool_opt_any_VFIO_setup}"; then
        case true in
            "${bool_arg_parse_file}" )
                readonly var_Parse_IOMMU="FILE"
                ;;

            "${bool_arg_parse_online}" )
                readonly var_Parse_IOMMU="DNS"
                ;;

            * )
                readonly var_Parse_IOMMU="LOCAL"
                ;;
        esac

        Parse_IOMMU "${var_Parse_IOMMU}" "${var_input1}" || exit "${?}"
        Select_IOMMU || exit "${?}"
    fi

    # <remarks> Execute pre-setup </remarks>
    if "${bool_opt_any_VFIO_setup}" || "${bool_opt_pre_setup}"; then
        AddUserToGroups
        Allocate_CPU
        Allocate_RAM
        exit            # TODO: debug here!
        RAM_Swapfile
        Virtual_KVM
        Modify_QEMU
    fi

    exit

    # <remarks> Execute main setup </remarks>
    if "${bool_opt_any_VFIO_setup}"; then
        Setup_VFIO || return "${?}"
    fi

    # <remarks> Execute post-setup </remarks>
    if "${bool_opt_post_setup}"; then
        VirtualAudioCapture
        VirtualVideoCapture
    fi

    exit "${?}"
# </code>