#!/bin/bash sh

exit 0	# until completion, leave this exit here		# to debug, uncomment this exit

# function steps #
# 1a.   Parse PCI and IOMMU groups, note each IOMMU group passedthrough.
# 1b.   No existing VFIO setup, warn user and immediately exit.
# 2a.   Create VM templates, with every possible config (excluding one given IOMMU group). Setup hugepages and other tweaks.
# 2b.   Set qemu enlightenments: evdev, hostdev (given VGA).
# 3.    Save VM templates to XML format, and output to directory. Restart libvirt to refresh.
#
# NOTE: worst comes to worst:
# -I cannot easily append VFIO devices to an XML
# -I cannot generate a valid XML
# Instead:
# -I generate as much useful output to a logfile, where the user may copy to his XML
#

# notify user to find or generate valid vbios (and patch if needed), and leave output for vbios string in XML 
#
#

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

## parameters ##
str_UUID=`uuidgen`
declare -a arr_XML=()

declare -i int_hostSocket=`echo $(lscpu | grep -Ei "socket" | grep -iv "core" | cut -d ':' -f2)`
declare -i int_hostCore=`echo $(lscpu | grep -Ei "core" | grep -Eiv "name|thread" | cut -d ':' -f2)`
declare -i int_hostThread=`echo $(lscpu | grep -Ei "thread" | cut -d ':' -f2)`
declare -i int_vThreadSum=$(( int_vThread * int_hostThread - 1))
declare -i int_vOffset=0

str_dir1="/etc/libvirt/qemu"

declare -a arr_compgen=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h`)  # IOMMU ID and Bus ID, sorted by IOMMU ID (left-most digit)
declare -a arr_lspci=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)            # dev name, Bus ID, and (sometimes) driver, sorted
declare -a arr_lspci_busID=(`lspci -m | cut -d '"' -f 1`)                               # Bus ID, sorted        (ex '01:00.0') 
declare -a arr_lspci_HWID=(`lspci -n | cut -d ' ' -f 3`)                                # HW ID, sorted         (ex '10de:1b81')
declare -a arr_lspci_type=(`lspci -m | cut -d '"' -f 2 | tr '[:lower:]' '[:upper:]'`)   # dev type, sorted      (ex 'VGA', 'GRAPHICS')

declare -a arr_lspci_driverName=()
declare -a arr_lspci_IOMMUID=()                                                         # strings of index(es) of every Bus ID and entry, sorted by IOMMU ID
declare -a arr_evdev=()

declare -i int_hugepageNum=0
str_hugepageSize=""

str_machineName="template_VM_Q35_UEFI"
##

# add support for socket count #


# set vcore count #
if [[ $int_hostCore -ge 4 ]]; then
    int_vOffset=2
    int_vCore=$(( int_hostSocket * ( $int_hostCore - $int_vOffset ) ))
else if [[ $int_hostCore == 3 ]]; then
    int_vOffset=1
    int_vCore=$(( int_hostSocket * 2 ))
else if [[ $int_hostCore == 2 ]]; then
    int_vOffset=0
    int_vCore=$int_hostSocket
else if [[ $int_hostCore == 2 ]]; then
    int_vCore=0
    echo "$0: Insufficient host resources (CPU cores). Skipping."
    exit 0
fi
#

echo $int_vCore

exit 0

declare -i int_vThread=$int_vCore*$int_hostThread

# set vcpu placement as such #
# save first two cores to host
# use rest for VM #
# start at core index '3' and add to vcpu placement
# if smt enabled (threads > 1), alt between core and thread for vcpu placement


## check for hugepages logfile ##
str_file1=`ls $(pwd)/functions | grep -i 'hugepages' | grep -i '.log'`

if [[ -z $str_file0 ]]; then
    echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute "`ls $(pwd)/functions | grep -i 'hugepages' | grep -i '.bash'`"'.\n"

else
    while read str_line1; do

        # parse hugepage size #
        if [[ $str_line1 == *"hugepagesz="* ]]; then
            str_hugepageSize=`echo $str_line1 | cut -d '=' -f2`
        fi
        #

        # parse hugepage num #
        if [[ $str_line1 == *"hugepages="* ]]; then
            int_hugepageNum=`echo $str_line1 | cut -d '=' -f2`
        fi
        #   
    done < $str_file1

    str_machineName+="_"$int_hugepageNum$str_hugepageSize
fi
##

## check for EVDEV ##
str_file2="/etc/libvirt/qemu.conf"
bool_readNextLine=false

while read str_line1; do

    #if [[ $str_line1 == *"# END #"* ]]; then
        #bool_readNextLine=false
        #break
    #fi

    #if [[ $str_line1 == *"# START #"* ]]; then
        #bool_readNextLine=true
    #fi

    if [[ $bool_readNextLine == true && $str_line1 == *"/dev/input/"* ]]; then
        arr_evdev+=(`echo $str_line1 | cut -d ',' -f1 | cut -d '"' -f2`)
    fi

    if [[ $str_line1 == *"cgroup_device_acl = ["* ]]; then
        bool_readNextLine=true
        str_machineName+="_EVDEV"
    fi

    if [[ $str_line1 == *"/dev/null"*||*"/dev/full"*||*"/dev/zero"*||*"/dev/random"*||*"/dev/urandom"*||*"/dev/ptmx"*||*"/dev/kvm"*||*"/dev/rtc"*||*"/dev/hpet" ]]; then
        bool_readNextLine=false
        break
    fi    

done < $str_file2
##


## find and sort drivers by Bus ID (lspci) ##
# parse Bus ID #
for (( int_i=0 ; int_i<${#arr_lspci_busID[@]} ; int_i++ )); do

    bool_readNextLine=false
    str_thatBusID=${arr_lspci_busID[$int_i]}
    #echo "$0: str_thatBusID == $str_thatBusID"

    # parse lspci info #
    for str_line1 in ${arr_lspci[@]}; do

        # 1 #
        # match boolean and driver, add to list #
        if [[ $bool_readNextLine == true && $str_line1 == *"driver"* ]]; then
            str_thisDriverName=`echo $str_line1 | grep "driver" | cut -d ' ' -f5`

            # vfio driver found, note input, add to list and update boolean #
            if [[ $str_thisDriverName == 'vfio-pci' ]]; then
                bool_isVFIOsetup=true
            fi
            #

            arr_lspci_driverName+=($str_thisDriverName)
            break
        fi
        #

        # 1 #
        # match boolean and false match line, add to list, reset boolean #
        if [[ $bool_readNextLine == true && $str_line1 != *"driver"* ]]; then
            arr_lspci_driverName+=("NO_DRIVER_FOUND")
            break
        fi

        # 2 #
        # match Bus ID, update boolean #
        if [[ $str_line1 == *$str_thatBusID* ]]; then
            bool_readNextLine=true
        fi
        #
    done
    #
done
##

## find and sort IOMMU IDs by Bus ID (lspci) ##
# parse list of Bus IDs #
for str_lspci_busID in ${arr_lspci_busID[@]}; do

    str_lspci_busID=${str_lspci_busID::-1}                                  # valid element
    #echo "$0: str_lspci_busID == '$str_lspci_busID'"

    # parse compgen info #
    for str_compgen in ${arr_compgen[@]}; do

        str_thisBusID=`echo $str_compgen | sort -h | cut -d '/' -f7`
        str_thisBusID=${str_thisBusID:5:10}                                 # valid element
        #echo "$0: str_thisBusID == $str_thisBusID"
        str_thisIOMMUID=`echo $str_compgen | sort -h | cut -d '/' -f5`      # valid element

        # match Bus ID, add IOMMU ID at index #
        if [[ $str_thisBusID == $str_lspci_busID ]]; then
            arr_lspci_IOMMUID+=($str_thisIOMMUID)                           # add to list
            break
        fi
        #
    done
    #
done
##

## parameters ##
readonly arr_lspci_driverName
readonly arr_lspci_IOMMUID
##

for str_lspci_driverName in ${arr_lspci_driverName[@]}; do
    echo "$0: str_lspci_driverName == $str_lspci_driverName"
done

for str_lspci_IOMMUID in ${arr_lspci_IOMMUID[@]}; do
    echo "$0: str_lspci_IOMMUID == $str_lspci_IOMMUID"
done


# sort IOMMU groups, add devices to list of vfio devices
for (( int_i=0 ; int_i<${#arr_lscpi_IOMMUID[@]} ; int_i++ )); do

    # match VFIO device #
    if [[ ${arr_lspci_driverName[$int_i]} == "vfio-pci" ]]; then

        # add to XML
        arr_lspci_VFIO+=($int_i)

        # match VGA device #
        if [[ ${arr_lspci_type[$int_i]} == *"VGA"* && ${arr_lspci_type[$int_i]} == *"GRAPHICS"* ]]; then
           arr_lspci_VFIO_VGA+=($int_i)
        fi
    fi
    #
done
#


WriteToXML {

	echo -en "$0: Creating virtual machine XML file. "
	
	## cputune ##

	str_XML_vcore_subtext="cpuset="
	declare -i int_i=1

	# setup vcpu placement #
	while [[ int_i -le $int_hostThread ]]; do

		declare -i int_vTemp=$int_hostThread*$int_i
		str_XML_vcore_subtext+="$int_vOffset-$int_vTemp,"
		((int_i++))

	done

	str_XML_vcore_subtext=${str_XML_vcore_subtext::-1}      # remove last delimiter
	arr_XML_vcore+=("    <vcpu placement=\"static\" $str_XML_vcore_subtext</vcpu>")
	#


	# vcpupin #
	# 1 #
	for (( int_i=0 ; int_i<$int_vThread ; int_i++ )); do    

		for (( int_j=0 ; int_j<$int_hostThread ; int_j++ )); do

			int_vSet=$(( $int_vOffset + $int_i + ( $int_hostCore*$int_j ) ))
			arr_vcore+=("        <vcpupin vcpu=\"$int_i\" cpuset=\"$int_vSet\"/>")

		done
	done

	# 2 #
	arr_XML_vcore+=(
	"        <iothreads>$int_hostThread</iothreads>
			<iothreadids>")

	# 3 #
	for (( int_i=1 ; int_i<$int_vThread ; int_i++ )); do    

		for (( int_j=0 ; int_j<$int_hostThread ; int_j++ )); do

			int_vIO=$(( int_i + ( $int_hostCore * $int_j ) ))

			arr_XML_vcore+=("            <iothread id=\"$int_vIO\"/>")

		done
	done

	# 4 #
	arr_XML_vcore+=(
	"        </iothreadids>
			<cputune>")

	# 5 #
	for (( int_i=1 ; int_i<$int_vThread ; int_i++ )); do    

		for (( int_j=0 ; int_j<$int_hostThread ; int_j++ )); do

			int_vIO=$(( int_i + ( $int_hostCore * $int_j ) ))
			str_vIO+="$int_vIO,"

		done

		str_vIO=${str_vIO::-1}  # remove last delimiter     # NOTE: does this work?
		arr_XML_vcore+=("            <emulatorpin cpuset=\"$str_vIO\"/>")

	done

	# 6 #
	for (( int_i=1 ; int_i<$int_vThread ; int_i++ )); do    

		for (( int_j=0 ; int_j<$int_hostThread ; int_j++ )); do

			int_vIO=$(( int_i + ( $int_hostCore * $int_j ) ))
			arr_XML_vcore+=("            <iothreadpin iothread=\"$int_i\" cpuset=\"$int_vIO\"/>")

		done
	done

	# 7 #
	arr_XML_vcore+=("        </cputune>")

	##

	## Hugepages
	# NOTE: copy check function for hugepages

	declare -a arr_XML_hugepages=(
	'        <hugepages/>
			<nosharepages/>
			<allocation mode="immediate"/>
			<discard/>')
	##

	## QEMU enlightenments and EVDEV
	# NOTE: parse evdev

	#echo "<qemu:arg value=\"-vga\"/>
	#	<qemu:arg value=\"none\"/>
	#	<qemu:arg value=\"-set\"/>
	#	<qemu:arg value=\"device.hostdev0.x-vga=on\"/>"

	declare -a arr_XML_QEMU=(
"    <qemu:commandline>
		<qemu:arg value=\"-overcommit\"/>
		<qemu:arg value=\"cpu-pm=on\"/>")

	# parse input devices #
	for (( int_i=0 ; int_i<${arr_evdev[@]} ; int_i++ )); do

		str_inputSuffix=""
		str_inputType=`echo ${arr_evdev[$int_i]} | grep -Ei "kbd|mouse" | cut -d '-' -f3`

		if [[ $str_inputType == *"kbm"*||*"keyboard"* ]]; then 
			str_inputSuffix=",grab_all=on,repeat=on"
		fi

		declare -a arr_XML_QEMU+=(			
"		<qemu:arg value=\"-object\"/>
		<qemu:arg value=\"input-linux,id=${str_inputType}${int_i},evdev=${str_inputDevice}${str_inputSuffix}\"/>")

	done
	#
	
	declare -a arr_XML_QEMU+=("    </qemu:commandline>")
	##

	## setup VFIO devices ##
	declare -i int_vBusID=11        # NOTE: find below the last hexadecmial VFIO Bus ID     
									# search:   '<address type="pci" domain="0x0000" bus="0x'   without ''

	for (( int_i=0 ; int_i<${arr_lspci_VFIO[@]} ; int_i++ )); do

		# find virtual Bus ID, convert string as base 16 #
		declare int_vBusID=$(( int_vBusID + int_i ))

		if [[ $int_vBusID -lt 16 ]]; then
			str_vBusID="00"
		fi

		if [[ $int_vBusID -le 127 && $int_vBusID -gt 16 ]]; then
			str_vBusID="0"
		fi

		str_vBusID+=`printf '%x\n' $int_vBusID`
		#

		# find VFIO Bus ID #
		int_lspci_VFIO=${arr_lspci_VFIO[$int_i]}
		str_thisBusID=`echo $(${arr_lspci_busID[$int_i]}) | cut -d ':' -f1`
		str_thisFuncID=`echo $(${arr_lspci_busID[$int_i]}) | cut -d '.' -f2`
		#

		declare -a arr_XML_VFIO+=(
	"<hostdev mode=\"subsystem\" type=\"pci\" managed=\"yes\">
		<driver name=\"vfio\"/> 
		<source>
			<address domain=\"0x0000\" bus=\"0x${str_thisBusID}\" slot=\"0x00\" function=\"0x${str_thisFuncID}\"/>
		</source>
		<address type=\"pci\" domain=\"0x0000\" bus=\"0x${str_vBusID}\" slot=\"0x00\" function=\"0x0\"/> 
	</hostdev>")

	done
	##

	## VM template ##
	# NOTE: need to generate UUID

	declare -a arr_XML=(
	"<domain xmlns:qemu=\"http://libvirt.org/schemas/domain/qemu/1.0\" type=\"kvm\">
		<name>${str_thisMachineName}</name>
		<uuid></uuid>
		<title>${str_thisMachineName}</title>
		<metadata>
			<libosinfo:libosinfo xmlns:libosinfo=\"http://libosinfo.org/xmlns/libvirt/domain/1.0\">
				<libosinfo:os id=\"http://microsoft.com/win/10\"/>
			</libosinfo:libosinfo>
		</metadata>
		<memory unit=\"KiB\">${int_machineMem}</memory>
		<currentMemory unit=\"KiB\">${int_machineMem}</currentMemory>
		<memoryBacking>
${arr_XML_hugepages}
		</memoryBacking>
${arr_XML_vcore}
		<resource>
			<partition>/machine</partition>
		</resource>
		<os>
			<type arch=\"x86_64\" machine=\"pc-q35-5.2\">hvm</type>
			<loader readonly=\"yes\" type=\"pflash\">/usr/share/OVMF/OVMF_CODE_4M.fd</loader>
			<nvram>/var/lib/libvirt/qemu/nvram/${str_newMachineName}_VARS.fd</nvram>
			<boot dev=\"hd\"/>
			<bootmenu enable=\"no\"/>
		</os>
		<features>
			<acpi/>
			<apic/>
			<hyperv>
				<relaxed state=\"on\"/>
				<vapic state=\"on\"/>
				<spinlocks state=\"on\" retries=\"8191\"/>
				<vpindex state=\"on\"/>
				<runtime state=\"on\"/>
				<synic state=\"on\"/>
				<stimer state=\"on\"/>
				<reset state=\"on\"/>
				<vendor_id state=\"on\" value=\"1234567890ab\"/>
				<frequencies state=\"on\"/>
			</hyperv>
			<kvm>
				<hidden state=\"on\"/>
			</kvm>
			<vmport state=\"off\"/>
			<ioapic driver=\"kvm\"/>
		</features>
		<cpu mode=\"host-passthrough\" check=\"none\" migratable=\"on\">
			<topology sockets=\"${int_hostSocket}\" dies=\"1\" cores=\"${int_vCore}\" threads=\"${int_vThread}\"/>
			<cache mode=\"passthrough\"/>
		</cpu>
		<clock offset=\"utc\">                                                                                          
			<timer name=\"rtc\" tickpolicy=\"catchup\"/>
			<timer name=\"pit\" tickpolicy=\"delay\"/>
			<timer name=\"hpet\" present=\"no\"/>
			<timer name=\"kvmclock\" present=\"no\"/>
			<timer name=\"hypervclock\" present=\"yes\"/>
			<timer name=\"tsc\" present=\"yes\" mode=\"native\"/>
		</clock>
		<on_poweroff>destroy</on_poweroff>
		<on_reboot>restart</on_reboot>
		<on_crash>destroy</on_crash>
		<pm>
			<suspend-to-mem enabled=\"yes\"/>
			<suspend-to-disk enabled=\"yes\"/>
		</pm>
		<devices>
			<emulator>/usr/bin/qemu-system-x86_64</emulator>
			<controller type=\"usb\" index=\"0\" model=\"qemu-xhci\" ports=\"15\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x02\" slot=\"0x00\" function=\"0x0\"/>
			</controller>
			<controller type=\"sata\" index=\"0\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x1f\" function=\"0x2\"/>
			</controller>
			<controller type=\"pci\" index=\"0\" model=\"pcie-root\"/>
			<controller type=\"pci\" index=\"1\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"1\" port=\"0x10\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x0\" multifunction=\"on\"/>
			</controller>
			<controller type=\"pci\" index=\"2\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"2\" port=\"0x11\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x1\"/>
			</controller>
			<controller type=\"pci\" index=\"3\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"3\" port=\"0x12\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x2\"/>
			</controller>
			<controller type=\"pci\" index=\"4\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"4\" port=\"0x13\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x3\"/>
			</controller>
			<controller type=\"pci\" index=\"5\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"5\" port=\"0x14\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x4\"/>
			</controller>
			<controller type=\"pci\" index=\"6\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"6\" port=\"0x15\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x5\"/>
			</controller>
			<controller type=\"pci\" index=\"7\" model=\"pcie-to-pci-bridge\">
				<model name=\"pcie-pci-bridge\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x03\" slot=\"0x00\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"8\" model=\"pci-bridge\">
				<model name=\"pci-bridge\"/>
				<target chassisNr=\"8\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x07\" slot=\"0x01\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"9\" model=\"pci-bridge\">
				<model name=\"pci-bridge\"/>
				<target chassisNr=\"9\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x07\" slot=\"0x02\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"10\" model=\"pci-bridge\">
				<model name=\"pci-bridge\"/>
				<target chassisNr=\"10\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x07\" slot=\"0x03\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"11\" model=\"pci-bridge\">
				<model name=\"pci-bridge\"/>
				<target chassisNr=\"11\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x07\" slot=\"0x04\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"12\" model=\"pci-bridge\">
				<model name=\"pci-bridge\"/>
				<target chassisNr=\"12\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x07\" slot=\"0x05\" function=\"0x0\"/>
			</controller>
			<controller type=\"pci\" index=\"13\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"13\" port=\"0x16\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x6\"/>
			</controller>
			<controller type=\"pci\" index=\"14\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"14\" port=\"0x17\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x02\" function=\"0x7\"/>
			</controller>
			<controller type=\"pci\" index=\"15\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"15\" port=\"0x18\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x03\" function=\"0x0\" multifunction=\"on\"/>
			</controller>
			<controller type=\"pci\" index=\"16\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"16\" port=\"0x19\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x03\" function=\"0x1\"/>
			</controller>
			<controller type=\"pci\" index=\"17\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"17\" port=\"0x1a\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x03\" function=\"0x2\"/>
			</controller>
			<controller type=\"pci\" index=\"18\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"18\" port=\"0x1b\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x03\" function=\"0x3\"/>
			</controller>
			<controller type=\"pci\" index=\"19\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"19\" port=\"0x8\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x01\" function=\"0x0\" multifunction=\"on\"/>
			</controller>
			<controller type=\"pci\" index=\"20\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"20\" port=\"0x9\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x01\" function=\"0x1\"/>
			</controller>
			<controller type=\"pci\" index=\"21\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"21\" port=\"0xa\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x01\" function=\"0x2\"/>
			</controller>
			<controller type=\"pci\" index=\"22\" model=\"pcie-root-port\">
				<model name=\"pcie-root-port\"/>
				<target chassis=\"22\" port=\"0xb\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x00\" slot=\"0x01\" function=\"0x3\"/>
			</controller>
			<controller type=\"scsi\" index=\"0\" model=\"virtio-scsi\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x0a\" slot=\"0x00\" function=\"0x0\"/>
			</controller>
			<interface type=\"network\">
				<mac address=\"52:54:00:e1:8a:73\"/>
				<source network=\"default\"/>
				<model type=\"virtio\"/>
				<link state=\"up\"/>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x01\" slot=\"0x00\" function=\"0x0\"/>
			</interface>
			<input type=\"mouse\" bus=\"ps2\"/>
			<input type=\"keyboard\" bus=\"ps2\"/>
			<input type=\"keyboard\" bus=\"virtio\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x04\" slot=\"0x00\" function=\"0x0\"/>
			</input>
			<input type=\"mouse\" bus=\"virtio\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x05\" slot=\"0x00\" function=\"0x0\"/>
			</input>
${arr_XML_VFIO}
			<memballoon model=\"virtio\">
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x06\" slot=\"0x00\" function=\"0x0\"/>
			</memballoon>
			<shmem name=\"looking-glass\">
				<model type=\"ivshmem-plain\"/>
				<size unit=\"M\">64</size>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x08\" slot=\"0x01\" function=\"0x0\"/>
			</shmem>
			<shmem name=\"scream-ivshmem\">
				<model type=\"ivshmem-plain\"/> 
				<size unit=\"M\">2</size>
				<address type=\"pci\" domain=\"0x0000\" bus=\"0x09\" slot=\"0x07\" function=\"0x0\"/>
			</shmem>
		</devices>
		<seclabel type=\"dynamic\" model=\"dac\" relabel=\"yes\"/>
${arr_XML_QEMU}
	</domain>")
	##

	echo -e "Complete."

}

# parse VFIO devices, create XML templates #
if [[ -e $arr_lspci_VFIO ]]; then

    echo -e "$0: VFIO devices found."
	str_thisMachineName=$str_machineName

    # parse VFIO VGA devices, create new XML for different primary VM boot VGA and append VM name #
    if [[ -e $arr_lspci_VFIO_VGA ]]; then

        echo -e "$0: VFIO VGA devices found."

        for (( int_i=0 ; int_i<${#arr_lspci_VFIO_VGA[@]} ; int_i++ )); do
            int_lspci_VFIO_VGA=${arr_lspci_VFIO_VGA[$int_i]}                # currently, function WriteToXML does not respect the idea I have implemented here
            str_thisMachineName="_GPU"$int_lspci_VFIO_VGA

			# boolean or some thing here to say 'hey, when you get to given VGA, set it's hostdev index as the boot vga
			# OR say 'set the given VGA as the first hostdev (hostdev0)'

			WriteToXML	# call function
        done   
    
	else

		echo -e "$0: No VFIO VGA devices found."

		for int_lspci_VFIO in ${arr_lspci_VFIO[@]}; do
        	WriteToXML	# call function
    	done

	fi
	#

else
    echo -e "$0: No VFIO devices found."
fi
#

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo "$0: Skipping."
exit 0