#!/bin/bash

# check if sudo #
if [[ `whoami` != "root" ]]; then
    echo "WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# set directories #
DIR1=`pwd`"/"
DIR2="/usr/sbin/"
DIR3="/etc/systemd/system/"
#

# copy files #
#cp $DIR1"Xorg-vfio-pci.sh" $DIR2"Auto-vfio-pci.sh"
cp $DIR1"Auto-Xorg.sh" $DIR2"Auto-Xorg.sh"
#cp $DIR1"Xorg-vfio-pci.service" $DIR3"Auto-vfio-pci.service"
cp $DIR1"Auto-Xorg.service" $DIR3"Auto-Xorg.service"
#

# set file permissions #
#chown root $DIR2"Auto-vfio-pci.sh"
#chmod 644 $DIR2"Auto-vfio-pci.sh"
chown root $DIR2"Auto-Xorg.sh"
chmod 644 $DIR2"Auto-Xorg.sh"
#chown root $DIR3"Auto-vfio-pci.service"
#chmod 644 $DIR3"Auto-vfio-pci.service"
chown root $DIR3"Auto-Xorg.service"
chmod 644 $DIR3"Auto-Xorg.service"
#

# setup services #
systemctl enable Auto-Xorg.service #Auto-vfio-pci.service
systemctl start Auto-Xorg.service #Auto-vfio-pci.service
systemctl daemon-reload
#

# prompt #
echo -e "NOTE: Run 'Auto-vfio-pci.sh' or 'systemctl start Auto-vfio-pci.service' once, for the first-time and for every new hardware-change.\nNOTE: It is NOT necessary to run 'Auto-Xorg.sh'. 'Auto-Xorg.service' will run automatically at boot, to grab the first available VGA device.\nIf no available VGA device is found, an Xorg template will be created. It will be assumed the system is running 'headless.'"
#

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0