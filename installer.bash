#!/bin/bash/env bash

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
    declare -g _SET_COLOR_GREEN='\033[0;32m'
    declare -g _SET_COLOR_RED='\033[0;31m'
    declare -g _SET_COLOR_YELLOW='\033[0;33m'
    declare -g _RESET_COLOR='\033[0m'

    # <summary> Append output </summary>
    declare -g _PREFIX_NOTE="${_SET_COLOR_YELLOW}Note:${_RESET_COLOR}"
    declare -g _PREFIX_ERROR="${_SET_COLOR_YELLOW}An error occurred:${_RESET_COLOR}"
    declare -g _PREFIX_FAIL="${_SET_COLOR_RED}Failure:${_RESET_COLOR}"
    declare -g _PREFIX_PASS="${_SET_COLOR_GREEN}Success:${_RESET_COLOR}"
# </params>

# <functions>
    function Main
    {
        if [[ $( whoami ) != "root" ]]; then
            echo -e "$_PREFIX_ERROR User is not sudo/root."
            return 1
        fi

        declare -g _BIN_DEST_PATH="/usr/local/bin/"
        declare -g _BIN_SOURCE_PATH="bin"
        declare -g _ETC_DEST_PATH="/usr/local/etc/vfiolib.d/"
        declare -g _ETC_SOURCE_PATH="etc"
        cd "$_BIN_SOURCE_PATH" || return 1

        if  [[ ! -e "deploy-vfio" ]] \
            || [[ ! -e "vfiolib-all" ]] \
            || [[ ! -e "vfiolib-calcs" ]] \
            || [[ ! -e "vfiolib-checks" ]] \
            || [[ ! -e "vfiolib-common" ]] \
            || [[ ! -e "vfiolib-pre-setup" ]] \
            || [[ ! -e "vfiolib-files" ]] \
            || [[ ! -e "vfiolib-globals" ]] \
            || [[ ! -e "vfiolib-parse" ]] \
            || [[ ! -e "vfiolib-setup" ]] \
            || [[ ! -e "vfiolib-usage" ]]; then
            echo -e "$_PREFIX_ERROR Missing project binaries."
            return 1
        fi

        cd .. || return 1
        cd "$_ETC_SOURCE_PATH" || return 1

        if [[ ! -e "audio-loopback-user.service" ]] \
            || [[ ! -e "custom" ]] \
            || [[ ! -e "grub" ]] \
            || [[ ! -e "initramfs-tools" ]] \
            || [[ ! -e "libvirt-nosleep@.service" ]] \
            || [[ ! -e "modules" ]] \
            || [[ ! -e "pci-blacklists.conf" ]] \
            || [[ ! -e "qemu.conf" ]] \
            || [[ ! -e "vfio.conf" ]]; then
            echo -e "$_PREFIX_ERROR Missing project files."
            return 1
        fi

        if [[ ! -d "$_BIN_DEST_PATH" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_BIN_DEST_PATH'."
            return 1
        fi

        if [[ ! -d "$_ETC_DEST_PATH" ]] \
            && ! sudo mkdir -p "$_ETC_DEST_PATH"; then
            echo -e "$_PREFIX_ERROR Could not create directory '$_ETC_DEST_PATH'."
            return 1
        fi

        cd ..
        cd "$_BIN_SOURCE_PATH" || return 1

        if ! sudo cp -rf * "$_BIN_DEST_PATH" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy project binaries."
            return 1
        fi

        cd .. || return 1
        cd "$_ETC_SOURCE_PATH" || return 1

        if ! sudo cp -rf * "$_ETC_DEST_PATH" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy project file(s)."
            return 1
        fi

        if ! sudo chown -R root:root "$_BIN_DEST_PATH" &> /dev/null \
            || ! sudo chmod -R +x "$_BIN_DEST_PATH" &> /dev/null \
            || ! sudo chown -R root:root "$_ETC_DEST_PATH" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to set file permissions."
            return 1
        fi

        return 0
    }
# </functions>

# <summary> Main </summary>
# <functions>
    Main

    if [[ "$?" -ne 0 ]]; then
        echo -e "$_PREFIX_FAIL Could not install deploy-VFIO."
        exit 1
    fi

    echo -e "$_PREFIX_PASS Installed deploy-VFIO."
    exit 0
# </functions>