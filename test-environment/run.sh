#!/bin/bash


FORCE=0
OCTOPRINT=1
TSD_SERVER=1


padding() {
	export WHILE_LENGTH=${#0}
	while [ ${WHILE_LENGTH} -ne 0 ]; do
		echo -en " "
		let WHILE_LENGTH--
	done
}

display_usage() {
	echo ""
	echo -en "\t${0}"
	echo -e "\t [--force|-force] [--octoprint|-op]"
	echo -en "\t" ; padding ; echo -e "\t [--tsd-server|-tsd] [--help|-help|--h|-h]"
	echo ""
	echo -en "\t" ; padding ; echo -e "\t --force, -force             Overwrite existing files without warning"
	echo -en "\t" ; padding ; echo -e "\t --octoprint, -op            Build OctoPrint test-environment only"
	echo -en "\t" ; padding ; echo -e "\t --tsd-server, -tsd          Build TSD-Server test-environment only"
	echo -en "\t" ; padding ; echo -e "\t --help, -help, --h, -h      Display this help message"
	echo ""
	echo ""
	exit 0
}


for argument in $@; do

	case ${argument} in


		'--force' | '-force')
			FORCE=1
			;;

		'--octoprint' | '-op')
			TSD_SERVER=0
			;;
		'--tsd-server' | '-tsd')
			OCTOPRINT=0
			;;
		'--help' | '--h' | '-help' | '-h')
			display_usage
			;;
		* )
			;;
	esac
done


echo ""
echo -en " --> Checking for VirtualBox >= 6.0.0 "
VIRTUALBOX_VERSION="`VBoxManage --version 2>/dev/null | cut -d '.' -f1`"
if [ 0${VIRTUALBOX_VERSION} -ge 6 ]; then
	echo "[ ok ]"
else
	echo "[ not found ]"
	echo ""
	echo "Please make sure you have VirtualBox >= v6.0.0 installed."
	echo ""
	echo "aborting."
	echo ""
	exit 1
fi
echo ""

echo ""
echo -en " --> Checking for Packer.io >= 1.7.0 "
PACKER_VERSION_MAJOR="`packer --version | cut -d '.' -f1`"
PACKER_VERSION_MINOR="`packer --version | cut -d '.' -f2`"
if [ 0${PACKER_VERSION_MAJOR} -eq 1 -a 0${PACKER_VERSION_MINOR} -ge 7 ]; then
	echo "[ ok ]"
else
	echo "[ not found ]"
	echo ""
	echo "Please make sure you have packer >= v1.7.0 installed."
	echo ""
	echo "aborting."
	echo ""
	exit 1
fi
echo ""

if [ ${OCTOPRINT} -eq 1 ]; then
	echo "***************************************************************************"
	echo "*          Now building OctoPrint test-environment (VirtualBox)           *"
	echo "***************************************************************************"

	if [ ${FORCE} -eq 0 ]; then
		packer build virtualbox-iso.builder.octoprint.json
	else
		packer build -force virtualbox-iso.builder.octoprint.json
	fi
fi


if [ ${TSD_SERVER} -eq 1 ]; then
	echo "***************************************************************************"
	echo "* Now building TheSpaghettiDetective server test-environment (VirtualBox) *"
	echo "***************************************************************************"
	
	if [ ${FORCE} -eq 0 ]; then
		packer build virtualbox-iso.builder.tsd-docker.json
	else
		packer build -force virtualbox-iso.builder.tsd-docker.json
	fi
fi


exit 0
