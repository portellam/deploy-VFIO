#!/usr/bin/env bash
#
# Author: Sebastiaan Meijer (sebastiaan@passthroughpo.st)
#
# This hook allows automatically switch monitor inputs when starting/stopping a VM.
# This file depends on the Passthrough POST hook helper script found in this repo.
# Place this script in BOTH these directories (or symlink it): 
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/started/begin/
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/stopped/end/
# $SYSCONFDIR usually is /etc/libvirt.
# Set the files as executable through `chmod +x` and configure your inputs.
# You also need `ddcutil` and a ddcutil-compatible monitor.
#
# Make sure you specify the right settings for your setup below or it won't work.

hex_domainDisplay="0"   # The display shown in `ddcutil detect`
hex_domainInput="12"    # The input the VM is connected to (without 0x, but with leading zeroes, if any. See `ddcutil capabilities`)
hex_hostInput="0f"      # The input the host is connected to (without 0x, but with leading zeroes, if any. See `ddcutil capabilities`)

if [[ "$2/$3" == "started/begin" ]]; then
    hex_input="$hex_domainInput"

elif [[ "$2/$3" == "stopped/end" ]]; then
    hex_input="$hex_hostInput"
fi

if [[ "$(ddcutil -d "$hex_domainDisplay" getvcp 60 --terse | awk '{print $4}')" != "x$hex_input" ]]; then
    ddcutil -d "$hex_domainDisplay" setvcp 60 "0x$hex_input"
fi