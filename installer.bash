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

# <code>
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

        if [[ -z "deploy-vfio" ]] \
            || [[ -z "deploy-vfio" ]] \
            || [[ -z "vfiolib-all" ]] \
            || [[ -z "vfiolib-calcs" ]] \
            || [[ -z "vfiolib-checks" ]] \
            || [[ -z "vfiolib-common" ]] \
            || [[ -z "vfiolib-essentials" ]] \
            || [[ -z "vfiolib-files" ]] \
            || [[ -z "vfiolib-globals" ]] \
            || [[ -z "vfiolib-parse" ]] \
            || [[ -z "vfiolib-select" ]] \
            || [[ -z "vfiolib-setup" ]] \
            || [[ -z "vfiolib-usage" ]]; then
            echo -e "$_PREFIX_ERROR Missing project binaries."
            return 1
        fi

        cd .. || return 1
        cd "$_ETC_SOURCE_PATH" || return 1

        if [[ -z "audio-loopback-user.service" ]] \
            || [[ -z "custom" ]] \
            || [[ -z "grub" ]] \
            || [[ -z "initramfs-tools" ]] \
            || [[ -z "libvirt-nosleep@.service" ]] \
            || [[ -z "modules" ]] \
            || [[ -z "pci-blacklists.conf" ]] \
            || [[ -z "qemu.conf" ]] \
            || [[ -z "scream-ivshmem-pipewire.service" ]] \
            || [[ -z "scream-ivshmem-pulseaudio.service" ]] \
            || [[ -z "vfio.conf" ]]; then
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