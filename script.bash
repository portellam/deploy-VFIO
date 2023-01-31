#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# <summary>
#
# </summary>

declare -gr str_repo_name="deploy-VFIO-setup"
declare -gr str_full_repo_name="portellam/${str_repo_name}"

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
        return "${int_exit_code}"
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
    # <param name="${arr[@]}"> string of array: the array </param>
    # <returns> exit code </returns>
    function PrintArray
    {
        # <params>
        declare -aI arr
        local readonly var_command='echo -e "${var_yellow}${arr[@]}${var_reset_color}"'
        # </params>

        if ! CheckIfVarIsValid "${arr[@]}" &> /dev/null; then
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
        local readonly str_no="N"
        local readonly str_yes="Y"
        declare -ar arr_count=( "1" "2" "3" )
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
        declare -ar arr_count=( "1" "2" "3" )
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
        declare -ar arr_count=( "1" "2" "3" )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            SaveExitCode
            echo -e "${str_output}"_multiple_choice_not_valid
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
        declare -ar arr_count=( "1" "2" "3" )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            echo -e "${str_output}"_multiple_choice_not_valid
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
        return "${int_exit_code}"
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
        return "${int_exit_code}"
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

# <summary> Business functions: Validation </summary>
# <code>
    function DetectExisting_VFIO
    {}

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
    function Parse_IOMMU
    {
        # <summary> Return value given if a device's bus ID is Internal or External PCI. </summary>
        function IsBusInternalOrExternal
        {
            # <params>
            declare -I str_device_bus
            # </params>

            case "${str_device_bus}" in
                "00" | "01" )
                    return 0
                    ;;
            esac

            return 1
        }

        # <summary> Append IOMMU group *once* to another list should it meet criteria. </summary>
        function MatchDeviceType
        {
            # <params>
            declare -I arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA bool_is_found_IGPU_full_name str_device_type str_device_vendor str_IGPU_full_name str_IOMMU_group
            # </params>

            case "${str_device_type}" in
                "3d" | "display" | "graphics" | "vga" )
                    if CheckIfVarIsValid "${arr_IOMMU_groups_with_VGA[@]}" && [[ "${str_IOMMU_group}" != "${arr_IOMMU_groups_with_VGA[-1]}" ]]; then
                        arr_IOMMU_groups_with_VGA+=( "${str_IOMMU_group}" )
                    fi

                    if [[ "${bool_is_found_IGPU_full_name}" == false ]]; then
                        IsBusInternalOrExternal && (
                            str_IGPU_full_name="${str_device_vendor} ${str_device_name}"
                            bool_is_found_IGPU_full_name == true
                        )
                    fi

                    if [[ "${bool_is_found_IGPU_full_name}" == true ]]; then
                        readonly str_IGPU_full_name
                    fi
                ;;

                "usb" )
                    if CheckIfVarIsValid "${arr_IOMMU_groups_with_USB[@]}" && [[ "${str_IOMMU_group}" != "${arr_IOMMU_groups_with_USB[-1]}" ]]; then
                        arr_IOMMU_groups_with_USB=( "${str_IOMMU_group}" )
                    fi
                ;;
            esac

            return 0
        }

        # <summary> Get all devices within a given IOMMU group. </summary>
        function GetDevicesInGroup
        {
            # <params>
            declare -I arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_group_devices
            declare -I arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA str_IGPU_full_name str_IOMMU_group
            local bool_is_found_IGPU_full_name=false
            # </params>

            for str_device in ${arr_group_devices[@]}; do
                local str_device_PCI="${str_device##"0000:"}"
                local str_device_bus=$( echo "${str_device_PCI}" | cut -d ":" -f 1 )
                declare -l str_device_driver=$( lspci -ms "${str_device}" | cut -d ':' -f2 )
                local str_device_name=$( lspci -ms "${str_device}" | cut -d '"' -f6 )
                declare -l str_device_type=$( lspci -ms "${str_device}" | cut -d '"' -f2 )
                local str_device_vendor=$( lspci -ms "${str_device}" | cut -d '"' -f4 )

                if ! CheckIfVarIsValid "${str_device_driver}" &> /dev/null || [[ "${str_device_driver}" == *"vfio-pci"* ]]; then
                    str_device_driver="N/A"
                fi

                str_device_driver="${str_device_driver##" "}"
                MatchDeviceType

                if IsBusInternalOrExternal; then
                    arr_IOMMU_groups_with_internal_bus+=( "${str_IOMMU_group}" )
                else
                    arr_IOMMU_groups_with_external_bus+=( "${str_IOMMU_group}" )
                fi

                arr_device_driver+=( "${str_device_driver}" )
                arr_device_IOMMU+=( "${str_IOMMU_group}" )
                arr_device_name+=( "${str_device_name}" )
                arr_device_PCI+=( "${str_device_PCI}" )
                arr_device_type+=( "${str_device_type}" )
                arr_device_vendor+=( "${str_device_vendor}" )
            done

            return 0
        }

        # <summary> Get all IOMMU groups on this system. </summary>
        function GetGroups
        {
            # <params>
            declare -I arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_group_devices arr_IOMMU_groups arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA str_IGPU_full_name str_IOMMU_group
            local bool_is_found_IGPU_full_name=false
            # </params>

            if ! CheckIfVarIsValid "${arr_IOMMU_groups[@]}" &> /dev/null;
                return 1
            fi

            for str_IOMMU_group in ${arr_IOMMU_groups[@]}; do
                if CheckIfVarIsValid "${str_IOMMU_group}" &> /dev/null; then
                    declare -a arr_group_devices=( $( eval "${var_get_devices_of_IOMMU_group}" ) )
                    GetDevicesInGroup
                fi
            done

            readonly arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_IOMMU_groups_with_external_bus arr_IOMMU_groups_with_internal_bus arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA

            return 0
        }

        # <params>
        local str_output="Parsing IOMMU groups..."
        local readonly var_get_last_IOMMU_group='basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 )'
        local readonly var_get_devices_of_IOMMU_group='ls "${str_IOMMU_group}/devices/"'
        local readonly var_get_IOMMU_groups='find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V'

        # NOTE: index 0 is empty, why?
        declare -agr arr_IOMMU_groups=( $( eval "${var_get_IOMMU_groups}" ) )
        declare -ag arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_IOMMU_groups_with_external_bus arr_IOMMU_groups_with_internal_bus arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA
        declare -igr int_last_IOMMU_group=$( eval "${var_get_last_IOMMU_group}" )
        declare -g str_IGPU_full_name="N/A"
        # </params>

        echo -e "${str_output}"

        GetGroups
        AppendPassOrFail "${str_output}"
        return "${?}"
    }

    function ReadFromFile_IOMMU
    {}

    function SaveToFile_IOMMU
    {}

    function Select_IOMMU
    {}
# </code>

# <summary> Business functions: Main setup </summary>
# <code>
    function Dynamic_VFIO
    {}

    function Static_VFIO
    {}

    function UpdateExisting_VFIO
    {}
# </code>

# <summary> Business functions: Pre/Post setup </summary>
# <code>
    # <summary> Add user to necessary user groups. </summary>
    function AddUserToGroups
    {
        # <params>
        declare -ar arr_user_groups(
            "input"
            "libvirt"
        )

        local readonly var_add_user_to_group='adduser "${str_user_name}" "${str_user_group}"'
        local readonly var_get_first_valid_user='getent passwd {1000..60000} | cut -d ":" -f 1'
        local readonly str_username=$( eval "${var_get_first_valid_user}" )
        # </params>

        # <remarks> Add user(s) to groups. </remarks>
        for str_user_group in "${arr_user_groups[@]}"; do
            eval "${var_add_user_to_group}" || return "${?}"
        done

        return 0
    }

    # <summary> isolcpus: Ask user to allocate host CPU cores (and/or threads), to reduce host overhead, and improve both host and virtual machine performance. </summary
    function Allocate_CPU
    {}

    # <summary> Hugepages: Ask user to allocate host memory (RAM) to 'hugepages', to eliminate the need to defragement memory, to reduce host overhead, and to improve both host and virtual machine performance. </summary
    function Allocate_RAM
    {
        # <params>
        declare -ar arr_choices=(
            "2M"
            "1G"
        )

        declare -g bool_is_setup_hugepages=false
        declare -gi int_huge_page_count=0
        declare -gi int_huge_page_kbit_size=0
        declare -gi int_huge_page_max_kbit_size=0
        declare -gir int_huge_page_min_kbit_size=4194304
        declare -gi int_huge_page_max=0
        declare -gi int_huge_page_min=0
        declare -g str_huge_page_byte_prefix=""
        declare -g str_hugepages_GRUB=""
        declare -g str_hugepages_QEMU=""

        local readonly str_output1="Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n"
        local readonly str_output2="Setup Hugepages?"
        local readonly var_get_host_max_mem='cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1'
        # </params>

        echo -e "${str_output1}"
        ReadInput "${str_output2}" || return "${?}"
        ReadMultipleChoiceIgnoreCase "${arr_choices[@]}" || return "${?}"
        var_input=""
        str_huge_page_byte_prefix="${var_input}"
        int_huge_page_max_kbit_size=$( eval "${var_get_host_max_mem}" )

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

        readonly int_huge_page_max=$(( $int_huge_page_min_kbit_size - $int_huge_page_min_kbit_size ))
        readonly int_HugePageMax=$(( $int_huge_page_max / $int_huge_page_kbit_size ))
        local readonly str_output3="Enter number of Hugepages (n * ${str_huge_page_byte_prefix})"

        ReadInputFromRangeOfTwoNums "${str_output3}" "${int_huge_page_min}" "${int_huge_page_max}" || return "${?}"
        readonly int_huge_page_count="${var_input}"

        readonly str_hugepages_GRUB="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
        bool_is_setup_hugepages=true
        return 0
    }

    # <summary> Ask user to setup audio loopback from the host's Line-in to active audio output. Useful for virtual machines with sound-cards (example: Creative SoundBlaster). </summary>
    function HostAudioLineIn
    {}

    function LibvirtHooks
    {}

    # <summary> zramswap: Ask user to setup a swap partition in host memory, to reduce swapiness to existing host swap partition(s)/file(s), and reduce chances of memory exhaustion as host over-allocates memory. </summary>
    function RAM_Swapfile
    {}

    # <summary> Evdev: Ask user to setup a virtual Keyboard-Video-Mouse swich (excluding the Video). Will allow a user to swap between active virtual machines and host, with the use of a pre-defined macro (example: 'L-CTRL' + 'R-CTRL'). </summary>
    function Virtual_KVM
    {
        # <params>
        declare -ga arr_event_devices=()
        declare -ga arr_input_devices=()

        declare -g bool_is_setup_evdev=false
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

        if ! CheckIfVarIsValid "${arr_event_devices[@]}" && ! CheckIfVarIsValid "${var_get_input_devices[@]}"; then
            return 1
        fi

        bool_is_setup_evdev=true
        return 0
    }

    # <summary> libvirt-qemu: Append necessary changes to QEMU system file, including user groups, Evdev, Hugepages, and NVRAM (for UEFI VMs). </summary>
    function ModifyQEMU
    {
        # <params>
        declare -a arr_file1_evdev_cgroups=()
        declare -ar arr_file1_default_cgroups=(
            "        \"/dev/null\", \"/dev/full\", \"/dev/zero\","
            "        \"/dev/random\", \"/dev/urandom\","
            "        \"/dev/ptmx\", \"/dev/kvm\","
            "        \"/dev/rtc\", \"/dev/hpet\""
        )

        local readonly str_daemon1="libvirtd"
        local readonly str_file1="/etc/apparmor.d/abstractions/libvirt-qemu"
        local readonly str_file1_backup="./files/etc_libvirt_qemu.conf"
        local readonly var_set_event_device='"        \"/dev/input/by-id/${str_event_device}\",'
        # </params>

        # <remarks> Backup system file and grab clean file from repository. </remarks>
        CreateBackupFile "${str_file1}"
        GoToScriptDir || return "${?}"
        CheckIfFileExists "${str_file1_backup}" || return "${?}"
        cp "${str_file1_backup}" "${str_file1}"

        # <remarks> Get Event devices. </remarks>
        if [[ "${bool_is_setup_evdev}" == true ]]; then
            for str_event_device in "${arr_event_devices[@]}"; do
                arr_file1_evdev_cgroups+=( $( eval "${var_set_event_device}" ) )
            done

            for str_event_device in "${arr_event_devices[@]}"; do
                arr_file1_evdev_cgroups+=( $( eval "${var_set_event_device}" ) )
            done
        fi

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
        if CheckIfVarIsValid "${str_user_name}"; then
            arr_file1_contents+=(
                "#"
                "### User permissions ###"
                "        user = \"${str_user_name}\""
                "        group = \"user\""
                "#"
            )
        else
            arr_file1_contents+=(
                "#"
                "### User permissions ###"
                "#         user = \"user\""
                "#         group = \"user\""
                "#"
            )
        fi

        # <remarks> Adds or omits validation for Hugepages. </remarks>
        if [[ "${bool_is_setup_hugepages}" == true ]]; then
            arr_file1_contents+=(
                "#"
                "### Hugepages ###"
                "        hugetlbfs_mount = \"/dev/hugepages\""
                "#"
            )
        else
            arr_file1_contents+=(
                "#"
                "### Hugepages ###"
                "#         hugetlbfs_mount = \"/dev/hugepages\""
                "#"
            )
        fi

        # <remarks> Adds or omits Event devices. </remarks>
        if CheckIfVarIsValid "${arr_file1_evdev_cgroups[@]}"; then
            arr_file1_contents+=(
                "#"
                "### Devices ###"
                "# cgroup_device_acl = ["
                "${arr_file1_evdev_cgroups[@]}"
                "${arr_file1_default_cgroups[@]}"
                "        ]"
                "#"
            )
        else
            arr_file1_contents+=(
                "#"
                "### Devices ###"
                "# cgroup_device_acl = ["
                "${arr_file1_default_cgroups[@]}"
                "        ]"
                "#"
            )
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

        # <remarks> End append. </remarks>
        declare -a arr_file=( "${arr_file1_contents[@]}" )
        WriteFile "${str_file1}" || return "${?}"

        # <remarks> Check if daemon exists and restart it. </remarks>
        CheckIfDaemonIsActiveOrNot "${str_daemon1}" || return "${?}"
        systemctl enable "${str_daemon1}" || return 1
        systemctl restart "${str_daemon1}" || return 1

        return 0
    }

    # <summary> LookingGlass: Ask user to setup direct-memory-access of video framebuffer from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
    function VirtualVideoCapture
    {}

    # <summary> Scream: Ask user to setup audio loopback from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
    function VirtualAudioCapture
    {}
# </code>