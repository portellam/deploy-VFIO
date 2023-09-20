#!/bin/bash/env bash

#
# Filename:       generate-evdev.bash
# Description:    Parses input devices, updates system files,
#                 (optionally) restarts system service,
#                 and dumps output to file in QEMU VM XML format.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

function print_evdev
{
  for input_device in $( ls /dev/input/by-id ); do
    line="$( ls -l /dev/input/by-id | grep --ignore-case "${input_device}" )"
    event_device="$( echo "${line}" | awk 'END { print $NF }' | cut --delimiter '/' --fields 2 )"

    echo -en "Input:\t${input_device}\nEvent:\t"

    if [[ "${event_device}" != "${input_device}" ]]; then
      echo -e "${event_device}\n"
    else
      echo -e "N/A\n"
    fi
  done
}

print_evdev
exit 0