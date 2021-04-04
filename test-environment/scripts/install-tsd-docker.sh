#!/bin/sh


if [ "`id -u`" != "0" ]; then
	>&2 echo ""
	>&2 echo "This script must be run as root."
	>&2 echo "Exiting."
	>&2 echo ""
	exit 1
fi


# enable stable community repository
sed -i 's/^#\([http|ftp|https].*\?\/.*\?[^edge]\/community\)$/\1/' /etc/apk/repositories

apk update


# install virtualbox-guest-additions
apk add virtualbox-guest-additions


# install docker
apk add docker

apk add docker-compose


# enable services upon boot
rc-update add virtualbox-guest-additions default
rc-update add docker default


# reboot
reboot