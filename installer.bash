#!/bin/bash/env bash

exit 1    # TODO: need to update this.

#
# Filename:       installer.bash
# Description:    Manages deploy-VFIO binaries and files.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

# <params>
  # <summary>Execution Flags</summary>
    declare -g DO_INSTALL=true

  # <summary>
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  # </summary>
    declare -g _SET_COLOR_GREEN='\033[0;32m'
    declare -g _SET_COLOR_RED='\033[0;31m'
    declare -g _SET_COLOR_YELLOW='\033[0;33m'
    declare -g _RESET_COLOR='\033[0m'

  # <summary>Append output</summary>
    declare -g _PREFIX_ERROR="${_SET_COLOR_YELLOW}An error occurred:${_RESET_COLOR}"
    declare -g _PREFIX_FAIL="${_SET_COLOR_RED}Failure:${_RESET_COLOR}"
    declare -g _PREFIX_PASS="${_SET_COLOR_GREEN}Success:${_RESET_COLOR}"
# </params>

# <functions>
  # <summary>Public functions</summary>
    function GetOption
    {
      case "${1}" in
        "-u" | "--uninstall" )
          DO_INSTALL=false ;;

        "-i" | "--install" )
          DO_INSTALL=true ;;

        "-h" | "--help" | * )
          PrintUsage
          return 1 ;;
      esac

      return 0
    }

    function Main
    {
      if [[ $( whoami ) != "root" ]]; then
        echo -e "${_PREFIX_ERROR} User is not sudo/root."
        return 1
      fi

      GetOption "${1}" || return 1

      local BIN_DEST_PATH="/usr/local/bin/"
      local BIN_SOURCE_PATH="bin"
      local ETC_DEST_PATH="/usr/local/etc/vfiolib.d/"
      local ETC_SOURCE_PATH="etc"

      if "${DO_INSTALL}"; then
        if ! Install; then
          echo -e "${_PREFIX_FAIL} Could not install deploy-VFIO."
          return 1
        else
          echo -e "${_PREFIX_PASS} Installed deploy-VFIO."
        fi
      else
        if ! Uninstall; then
          echo -e "${_PREFIX_FAIL} Could not uninstall deploy-VFIO."
          return 1
        else
          echo -e "${_PREFIX_PASS} Uninstalled deploy-VFIO."
        fi

      fi

      return 0
    }

  # <summary>Private functions</summary>
    function DoBinariesExist
    {
      cd "${BIN_SOURCE_PATH}" || return 1

      if  [[ ! -e "deploy-vfio" ]] \
        || [[ ! -e "vfiolib-all" ]] \
        || [[ ! -e "vfiolib-checks" ]] \
        || [[ ! -e "vfiolib-common" ]] \
        || [[ ! -e "vfiolib-pre-setup" ]] \
        || [[ ! -e "vfiolib-files" ]] \
        || [[ ! -e "vfiolib-parse" ]] \
        || [[ ! -e "vfiolib-setup" ]] \
        || [[ ! -e "vfiolib-usage" ]]; then
        echo -e "${_PREFIX_ERROR} Missing project binaries."
        return 1
      fi

      return 0
    }

    function DoFilesExist
    {
      cd .. || return 1
      cd "${ETC_SOURCE_PATH}" || return 1

      if [[ ! -e "audio-loopback-user.service" ]] \
        || [[ ! -e "custom" ]] \
        || [[ ! -e "grub" ]] \
        || [[ ! -e "initramfs-tools" ]] \
        || [[ ! -e "libvirt-nosleep@.service" ]] \
        || [[ ! -e "modules" ]] \
        || [[ ! -e "pci-blacklists.conf" ]] \
        || [[ ! -e "qemu.conf" ]] \
        || [[ ! -e "vfio.conf" ]]; then
        echo -e "${_PREFIX_ERROR} Missing project files."
        return 1
      fi

      return 0
    }

    function DoesDestinationPathExist
    {
      if [[ ! -d "${BIN_DEST_PATH}" ]]; then
        echo -e "${_PREFIX_ERROR} Could not find directory '${BIN_DEST_PATH}'."
        return 1
      fi

      if [[ ! -d "${ETC_DEST_PATH}" ]] \
        && ! sudo mkdir -p "${ETC_DEST_PATH}"; then
        echo -e "${_PREFIX_ERROR} Could not create directory '${ETC_DEST_PATH}'."
        return 1
      fi

      return 0
    }

    function CopyFilesToDesination
    {
      cd ..
      cd "${BIN_SOURCE_PATH}" || return 1

      if ! sudo cp -rf * "${BIN_DEST_PATH}" &> /dev/null; then
        echo -e "${_PREFIX_ERROR} Failed to copy project binaries."
        return 1
      fi

      cd .. || return 1
      cd "${ETC_SOURCE_PATH}" || return 1

      if ! sudo cp -rf * "${ETC_DEST_PATH}" &> /dev/null; then
        echo -e "${_PREFIX_ERROR} Failed to copy project file(s)."
        return 1
      fi

      return 0
    }

    function Install
    {
      DoBinariesExist || return 1
      DoFilesExist || return 1
      DoesDestinationPathExist || return 1
      CopyFilesToDesination || return 1
      SetFilePermissions || return 1
    }

    function PrintUsage
    {
      IFS=$'\n'

      local -a OUTPUT=(
        "Usage:\tbash installer [OPTION]"
        "Manages deploy-VFIO binaries and files.\n"
        "  -h, --help\t\tPrint this help and exit."
        "  -i, --install\t\tInstall project to system."
        "  -u, --uninstall\tUninstall project from system."
      )

      echo -e "${OUTPUT[*]}"
      unset IFS
      return 0
    }

    function SetFilePermissions
    {
      if ! sudo chown -R root:root "${BIN_DEST_PATH}" &> /dev/null \
        || ! sudo chmod -R +x "${BIN_DEST_PATH}" &> /dev/null \
        || ! sudo chown -R root:root "${ETC_DEST_PATH}" &> /dev/null; then
        echo -e "${_PREFIX_ERROR} Failed to set file permissions."
        return 1
      fi

      return 0
    }

    function Uninstall
    {
      local EXECUTABLE="deploy-vfio"
      local SOURCES="vfiolib"

      cd "${BIN_DEST_PATH}" || return 1

      if ( [[ -e "${EXECUTABLE}" ]] \
          && ! rm -rf "./${EXECUTABLE}" &> /dev/null ) \
        || ( ls "./${SOURCES}-"* &> /dev/null \
          && ! rm -rf "./${SOURCES}-"* &> /dev/null ); then
        echo -e "${_PREFIX_ERROR} Failed to delete project binarie(s)."
        return 1
      fi

      if [[ -d "${ETC_DEST_PATH}" ]] \
        && ! rm -rf "${ETC_DEST_PATH}" &> /dev/null; then
        echo -e "${_PREFIX_ERROR} Failed to delete project file(s)."
        return 1
      fi

      return 0
    }
# </functions>

# <main>
  Main "${1}"
  exit "${?}"
# </main>