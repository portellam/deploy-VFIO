#!/bin/bash sh

#
# Filename:         installer.bash
# Description:      Installs deploy-VFIO binaries and files.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <params>
    # <summary>
    # Color coding
    # Reference URL: 'https://www.shellhacks.com/bash-colors'
    # </summary>
    declare -gr _SET_COLOR_GREEN='\033[0;32m'
    declare -gr _SET_COLOR_RED='\033[0;31m'
    declare -gr _SET_COLOR_YELLOW='\033[0;33m'
    declare -gr _RESET_COLOR='\033[0m'

    # <summary> Append output </summary>
    declare -gr _PREFIX_NOTE="${_SET_COLOR_YELLOW}Note:${_RESET_COLOR}"
    declare -gr _PREFIX_ERROR="${_SET_COLOR_YELLOW}An error occurred:${_RESET_COLOR}"
    declare -gr _PREFIX_FAIL="${_SET_COLOR_RED}Failure:${_RESET_COLOR}"
    declare -gr _PREFIX_PASS="${_SET_COLOR_GREEN}Success:${_RESET_COLOR}"
# </params>

# <code>
    function Main
    {
        if [[ $( whoami ) != "root" ]]; then
            echo -e "$_PREFIX_ERROR User is not sudo/root."
            return 1
        fi

        declare -gr _PATH_1="/usr/local/bin/"
        declare -gr _PATH_2="vfiolib/"
        declare -gr _PATH_3="${_PATH_2}files/"

        if [[ -z "${_PATH_2}deploy-vfio" ]] \
            || [[ -z "${_PATH_2}deploy-vfio" ]] \
            || [[ -z "${_PATH_2}vfiolib-all" ]] \
            || [[ -z "${_PATH_2}vfiolib-extras" ]] \
            || [[ -z "${_PATH_2}vfiolib-files" ]] \
            || [[ -z "${_PATH_2}vfiolib-iommu" ]] \
            || [[ -z "${_PATH_2}vfiolib-setup" ]] \
            || [[ -z "${_PATH_2}vfiolib-usage" ]] \
            || [[ -z "${_PATH_2}vfiolib-utils" ]]; then
            echo -e "$_PREFIX_ERROR Missing project binaries."
            return 1
        fi

        if [[ -z "${_PATH_3}custom" ]] \
            || [[ -z "${_PATH_3}grub" ]] \
            || [[ -z "${_PATH_3}initramfs-tools" ]] \
            || [[ -z "${_PATH_3}modules" ]] \
            || [[ -z "${_PATH_3}pci-blacklists.conf" ]] \
            || [[ -z "${_PATH_3}qemu.conf" ]] \
            || [[ -z "${_PATH_3}vfio.conf" ]]; then
            echo -e "$_PREFIX_ERROR Missing project files."
            return 1
        fi

        if [[ ! -d "$_PATH_1" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_PATH_1'."
            return 1
        fi

        if [[ ! -d "$_PATH_2" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_PATH_2'."
            return 1
        fi

        if ! sudo cp -rf "$_PATH_2" "_PATH_1" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy file(s)."
            return 1
        fi

        if ! chown -R root:root "$_PATH_2" &> /dev/null \
            || ! chmod +x "$_PATH_2/*" &> /dev/null \; then
            echo -e "$_PREFIX_ERROR Failed to set file permissions."
            return 1
        fi

        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    Main

    if [[ "$?" -ne 0 ]]; then
        echo -e "$_PREFIX_FAIL Could not install deploy-VFIO."
        exit 1
    fi

    echo -e "$_PREFIX_PASS Installed deploy-VFIO."
    exit 0
# </code>