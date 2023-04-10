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

        declare -gr _BIN_DEST_PATH="/usr/local/bin/"
        declare -gr _BIN_SOURCE_PATH="bin/vfiolib/"
        declare -gr _ETC_DEST_PATH="/usr/local/etc/"
        declare -gr _ETC_SOURCE_PATH="etc/vfiolib/"

        if [[ -z "${_BIN_SOURCE_PATH}deploy-vfio" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}deploy-vfio" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-tools" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-extras" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-files" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-iommu" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-setup" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-usage" ]] \
            || [[ -z "${_BIN_SOURCE_PATH}vfiolib-essentials" ]]; then
            echo -e "$_PREFIX_ERROR Missing project binaries."
            return 1
        fi

        if [[ -z "${_ETC_SOURCE_PATH}custom" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}grub" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}initramfs-tools" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}modules" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}pci-blacklists.conf" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}qemu.conf" ]] \
            || [[ -z "${_ETC_SOURCE_PATH}vfio.conf" ]]; then
            echo -e "$_PREFIX_ERROR Missing project files."
            return 1
        fi

        if [[ ! -d "$_BIN_DEST_PATH" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_BIN_DEST_PATH'."
            return 1
        fi

        if [[ ! -d "$_ETC_DEST_PATH" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_ETC_DEST_PATH'."
            return 1
        fi

        if ! sudo cp -rf "$_BIN_SOURCE_PATH" "$_BIN_DEST_PATH" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy project binaries."
            return 1
        fi

        if ! sudo cp -rf "$_ETC_SOURCE_PATH" "$_ETC_DEST_PATH" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy project file(s)."
            return 1
        fi

        if ! sudo chown -R root:root "$_BIN_DEST_PATH" &> /dev/null \
            || ! sudo chmod -R +x "${_BIN_DEST_PATH}vfiolib" &> /dev/null \
            || ! sudo chown -R root:root "$_ETC_DEST_PATH" &> /dev/null; then
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