#!/bin/sh


if [ "`id -u`" != "0" ]; then
	>&2 echo ""
	>&2 echo "This script must be run as root."
	>&2 echo "Exiting."
	>&2 echo ""
	exit 1
fi


# create directory and download tsd-sources
mkdir src

cd src

wget https://github.com/TheSpaghettiDetective/TheSpaghettiDetective/archive/refs/heads/master.zip

mv master.zip TheSpaghettiDetective.zip

unzip TheSpaghettiDetective.zip

mv TheSpaghettiDetective-master TheSpaghettiDetective

cd TheSpaghettiDetective


# install the tsd-server
docker-compose up -d