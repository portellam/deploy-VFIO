#!/bin/bash/env bash

#
# Filename:       generate-evdev.bash
# Description:    Parses input devices, updates system files,
#                 (optionally) restarts system service,
#                 and dumps output to file in QEMU VM XML format.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

# TODO:
# -whitelist only keyboard and/or mouse devices, and their related devices.
# -parse all devices.
# -append output if specified user or set to default (root).
# -append output if hugepages is enabled.

# <params>
  declare -gr PREFIX="${0}: "

  # <summary>
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  # </summary>
    declare -gr SET_COLOR_GREEN='\033[0;32m'
    declare -gr SET_COLOR_RED='\033[0;31m'
    declare -gr SET_COLOR_YELLOW='\033[0;33m'
    declare -gr RESET_COLOR='\033[0m'

  # <summary>Append output</summary>
    declare -gr PREFIX_ERROR="${PREFIX}${SET_COLOR_YELLOW}An error occurred:${RESET_COLOR} "
    declare -gr PREFIX_FAIL="${PREFIX}${SET_COLOR_RED}Failure:${RESET_COLOR} "
    declare -gr PREFIX_PASS="${PREFIX}${SET_COLOR_GREEN}Success:${RESET_COLOR} "

  declare EXCLUSIVE_KBM=true
  declare -gA INPUT_EVENT_DICTIONARY

  # <remarks>Filenames</remarks>
    declare -gr APPARMOR_QEMU_DEST_PATH="/etc/apparmor.d/local/abstractions/libvirt-qemu"
    declare -gr QEMU_DEST_PATH="/etc/libvirt/qemu.conf"
    declare -gr QEMU_SRC_PATH=$( dirname "${0}" )"/qemu.conf"
# </params>

# <summary>Loggers/summary>
  function print_error_to_log
  {
      echo -e "${PREFIX_ERROR}${1}" >&2
  }

  function print_fail_to_log
  {
    echo -e "${PREFIX_FAIL}${1}" >&2
  }

  function print_output_to_log
  {
    echo -e "${PREFIX_PROMPT}${1}" >&1
  }

# <summary>Data-type validation</summary>
  function is_enum
    {
      local -n this_enum="${1}"

      if ! [[ "${#this_enum[@]}" -gt 0 ]]; then
        print_error_to_log "Invalid enum."
        return 1
      fi
    }

    function is_enum_not_empty
    {
      is_enum "${1}" || return 1
      local -n this_enum="${1}"

      for value in "${this_enum[@]}"; do
        if is_string "${value}" &> /dev/null; then
          return 0
        fi
      done

      print_error_to_log "Empty enum."
      return 1
    }

# <summary>File manipulation</summary>
  function append_to_file_correctly
  {
    if ! [[ -e "${2}" ]] \
      || [[ -z "${1}" ]]; then
      return 1
    fi

    local -nr reference="${1}"
    local -r file="${2}"

    for line in ${reference[*]}; do
      if ! sudo echo -e "${line}" >> "${file}"; then
        print_error_to_log "Could not append to file '${file}'."
        return 1
      fi
    done
  }

# <summary>Business functions</summary>
  function get_evdev
  {
    for input_device in $( ls /dev/input/by-id ); do
      local line="$( ls -l /dev/input/by-id | grep --ignore-case "${input_device}" )"
      local event_device="$( echo "${line}" | awk 'END { print $NF }' | cut --delimiter '/' --fields 2 )"

      if [[ "${event_device}" == "${input_device}" ]]; then
        event_device=""
      fi

      INPUT_EVENT_DICTIONARY["${input_device}"]="${event_device}"
    done

    for input_device in "${!INPUT_EVENT_DICTIONARY[@]}"; do
      local event_device="${INPUT_EVENT_DICTIONARY["${input_device}"]}"
      local event_id=$( echo "${event_device}" | grep --only-matching --extended-regexp '[0-9]+' )

      # NOTE: Check if input device is a keyboard, mouse, both, or related.
      if "${EXCLUSIVE_KBM}" \
        && ! $( echo "${input_device}" | grep --ignore-case --regexp="kbd" --regexp="mouse" &> /dev/null ) \
        && ! $( xinput list --short "${event_id}" | grep --regexp "keyboard" --regexp "pointer" &> /dev/null ); then
          unset INPUT_EVENT_DICTIONARY["${input_device}"]
      fi
    done

    if "${EXCLUSIVE_KBM}"; then
      echo -e "${PREFIX}Whitelisting only Keyboard and Mouse devices."
    fi

    if ! is_enum_not_empty "INPUT_EVENT_DICTIONARY"; then
      return 1
    fi

    readonly INPUT_EVENT_DICTIONARY
  }

  function print_evdev
  {
    echo -e "${PREFIX}Below is a list of referenced device IDs, and their actual device IDs (Event and Input devices, respectively)."
    echo -e "${PREFIX}You may copy the Event device ID, and append it to Evdev (QEMU commandline for a Virtual KVM (Keyboard-Video-Mouse) or peripheral switch)."
    echo -e "\tEvent ID\tInput ID"

    for input_device in "${!INPUT_EVENT_DICTIONARY[@]}"; do
      local event_device="${INPUT_EVENT_DICTIONARY["${input_device}"]}"
      echo -en "\t"

      if [[ -z "${event_device}" ]]; then
        event_device="N/A"
      fi

      echo -en "${event_device}\t\t"
      echo -en "${input_device}"
      echo
    done
  }

  function restart_service
  {
    if ! systemctl restart libvirtd &> /dev/null; then
      print_error_to_log "Could not restart system service 'libvirtd.'"
      return 1
    fi
  }

  function write_to_files
  {
    local -a file1_output=(
      ""
      "### User permissions ###"
      "group = \"user\""
    )

    local -a file2_output=()

    if "${UNDO_CHANGES}"; then
      file1_output+=(
        "user = \"${USER}\""
      )
    else
      local -r login_user=$( who am i | awk '{print $1}' )

      file1_output+=(
        "user = \"${login_user}\""
      )
    fi

    file1_output=(
      ""
      "### Hugepages ###"
    )

    file2_output+=(
        ""
        "# Hugepages"
      )

    if "${UNDO_CHANGES}" \
      || ! "${ENABLE_HUGEPAGES}"; then
      file1_output+=(
        "#hugetlbfs_mount = \"/dev/hugepages\""
      )

      file2_output+=(
        "# /dev/hugepages rw,"
      )
    else
      file1_output+=(
        "hugetlbfs_mount = \"/dev/hugepages\""
      )

      file2_output+=(
        "/dev/hugepages rw,"
      )
    fi

    local -a file1_cgroups_output

    if ! "${UNDO_CHANGES}"; then
      for input_device in ${INPUT_EVENT_DICTIONARY[@]}; do
        file1_cgroups_output+=( "    \"/dev/input/by-id/${input_device}\"," )
      done

      for input_device in ${INPUT_DEVICES_ENUM[@]}; do
        file1_cgroups_output+=( "    \"/dev/input/by-id/${input_device}\"," )
      done
    fi

    file1_output+=(
      ""
      "### Devices ###"
      "cgroup_device_acl = ["
    )

    file2_output+=(
        ""
        "# Evdev"
    )

    local -a file1_default_cgroups_output=(
      "    \"/dev/null\", \"/dev/full\", \"/dev/zero\","
      "    \"/dev/random\", \"/dev/urandom\","
      "    \"/dev/ptmx\", \"/dev/kvm\","
      "    \"/dev/rtc\", \"/dev/hpet\""
    )

    if ${PRE_SETUP_DO_EXECUTE_EVDEV}; then
      file1_output+=(
        "${file1_cgroups_output[@]}"
        "${file1_default_cgroups_output[@]}"
        "]"
      )

      file2_output+=(
        "/dev/input/* rw,"
        "/dev/input/by-id/* rw,"
      )
    else
      file1_output+=(
        "${file1_default_cgroups_output[@]}"
        "]"
      )

      file2_output+=(
        "# /dev/input/* rw,"
        "# /dev/input/by-id/* rw,"
      )
    fi

    file1_output+=(
      ""
      "nvram = ["
      "    \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\","
      "    \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\","
      "    \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\","
      "    \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\""
      "]"
    )

    if ! append_to_file_correctly "file1_output" "${QEMU_DEST_PATH}" \
      || ! append_to_file_correctly "file2_output" "${APPARMOR_QEMU_DEST_PATH}" \
      || ! restart_service; then
      return 1
    fi
  }

function main
{
  get_evdev
  print_evdev

  if ! write_to_files; then
    print_fail_to_log "Could not generate Evdev setup."
    return 1
  fi
}

main
exit "${?}"