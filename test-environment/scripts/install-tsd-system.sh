#!/bin/sh


if [ "`id -u`" != "0" ]; then
	>&2 echo ""
	>&2 echo "This script must be run as root."
	>&2 echo "Exiting."
	>&2 echo ""
	exit 1
fi


# populate answers file
cat >> ~/answers.lst << "EOF"
# Use US layout with US variant
KEYMAPOPTS="${ALPINE_INSTALL_KEYMAP} ${ALPINE_INSTALL_VARIANT}"

# Set hostname to tsd-duet-bridge-docker
HOSTNAMEOPTS="-n ${ALPINE_INSTALL_HOSTNAME}"

# Contents of /etc/network/interfaces
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
	hostname ${ALPINE_INSTALL_HOSTNAME}
"

# DNS options (domain, nameserver)
DNSOPTS="-d ${ALPINE_INSTALL_DOMAIN} ${ALPINE_INSTALL_NAMESERVER}"

# Set timezone to UTC
TIMEZONEOPTS="-z ${ALPINE_INSTALL_TIMEZONE}"

# Set http/ftp proxy
PROXYOPTS="${ALPINE_INSTALL_PROXY}"

# Add a random mirror
APKREPOSOPTS="-r"

# Install Openssh
SSHDOPTS="-c openssh"

# Use openntpd
NTPOPTS="-c busybox"

# Use /dev/sda as a system disk
DISKOPTS="-m sys /dev/sda"
EOF

# install system
echo "y" | setup-alpine -e -f ~/answers.lst