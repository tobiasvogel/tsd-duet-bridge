#!/bin/bash


if [ "`id -u`" != "0" ]; then
	>&2 echo ""
	>&2 echo "This script must be run as root."
	>&2 echo "Exiting."
	>&2 echo ""
	exit 1
fi


# install tsd-plugin
/opt/OctoPrint/venv/bin/pip install "https://github.com/TheSpaghettiDetective/OctoPrint-TheSpaghettiDetective/archive/master.zip"