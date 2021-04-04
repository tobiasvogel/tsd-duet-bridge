#!/bin/bash


if [ "`id -u`" != "0" ]; then
	>&2 echo ""
	>&2 echo "This script must be run as root."
	>&2 echo "Exiting."
	>&2 echo ""
	exit 1
fi


# suppress sudo warning
touch /home/octoprint/.sudo_as_admin_successful
touch /var/lib/sudo/lectured/octoprint
chown root:octoprint /var/lib/sudo/lectured/octoprint
chmod 600 /var/lib/sudo/lectured/octoprint
echo -e "Defaults\tlecture=\"never\"" >> /etc/sudoers.d/99-suppress-sudo-warning
chmod 440 /etc/sudoers.d/99-suppress-sudo-warning
sudo -k


# upgrade the system to the latest packages and make sure
# all prerequisites are met
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip python3-dev python3-setuptools python3-venv git libyaml-dev build-essential linux-headers-686 net-tools mlocate


# install vbox guest-additions
mkdir /mnt/vboxiso
mount -o loop,ro /home/octoprint/VBoxGuestAdditions.iso /mnt/vboxiso
cd /mnt/vboxiso
./VBoxLinuxAdditions.run
cd ~
umount /mnt/vboxiso
rmdir /mnt/vboxiso
rm /home/octoprint/VBoxGuestAdditions.iso


# install octoprint
cd /opt
install -d -o octoprint -g octoprint -m 755 OctoPrint 
cd OctoPrint
su -l octoprint -c "cd /opt/OctoPrint && python3 -m venv venv"
su -l octoprint -c "cd /opt/OctoPrint && source venv/bin/activate && pip3 install pip --upgrade && rm -r ~/.cache/pip && pip3 install --no-cache-dir wheel &&  pip3 install --no-cache-dir octoprint && deactivate"
wget --quiet https://github.com/OctoPrint/OctoPrint/raw/master/scripts/octoprint.service
mv octoprint.service /etc/systemd/system/octoprint.service
sed -i 's/^ExecStart=\/home\/pi/ExecStart=\/opt/' /etc/systemd/system/octoprint.service
sed -i 's/^User=pi/User=octoprint/' /etc/systemd/system/octoprint.service
systemctl enable octoprint.service


# install haproxy for easy access of octoprint
DEBIAN_FRONTEND=noninteractive apt-get -y install haproxy
mv /etc/haproxy/haproxy.cfg{,.orig}
echo "global" > /etc/haproxy/haproxy.cfg
echo -e "\tmaxconn 4096" >> /etc/haproxy/haproxy.cfg
echo -e "\tuser haproxy" >> /etc/haproxy/haproxy.cfg
echo -e "\tgroup haproxy" >> /etc/haproxy/haproxy.cfg
echo -e "\tdaemon" >> /etc/haproxy/haproxy.cfg
echo -e "\tlog 127.0.0.1 local0 debug" >> /etc/haproxy/haproxy.cfg
echo "" >> /etc/haproxy/haproxy.cfg
echo "defaults" >> /etc/haproxy/haproxy.cfg
echo -e "\tlog     global" >> /etc/haproxy/haproxy.cfg
echo -e "\tmode    http" >> /etc/haproxy/haproxy.cfg
echo -e "\toption  httplog" >> /etc/haproxy/haproxy.cfg
echo -e "\toption  dontlognull" >> /etc/haproxy/haproxy.cfg
echo -e "\tretries 3" >> /etc/haproxy/haproxy.cfg
echo -e "\toption redispatch" >> /etc/haproxy/haproxy.cfg
echo -e "\toption http-server-close" >> /etc/haproxy/haproxy.cfg
echo -e "\toption forwardfor" >> /etc/haproxy/haproxy.cfg
echo -e "\tmaxconn 2000" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout connect 5s" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout client  15min" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout server  15min" >> /etc/haproxy/haproxy.cfg
echo "" >> /etc/haproxy/haproxy.cfg
echo "frontend public" >> /etc/haproxy/haproxy.cfg
echo -e "\tbind :::80 v4v6" >> /etc/haproxy/haproxy.cfg
echo -e "\tdefault_backend octoprint" >> /etc/haproxy/haproxy.cfg
echo "" >> /etc/haproxy/haproxy.cfg
echo "backend octoprint" >> /etc/haproxy/haproxy.cfg
echo -e "\treqrep ^([^\ :]*)\ /(.*)     \1\ /\2" >> /etc/haproxy/haproxy.cfg
echo -e "\toption forwardfor" >> /etc/haproxy/haproxy.cfg
echo -e "\tserver octoprint1 127.0.0.1:5000" >> /etc/haproxy/haproxy.cfg
service haproxy restart

# remove wireless tools and rename adapter to eth0
DEBIAN_FRONTEND=noninteractive apt-get -y remove --purge wpasupplicant wireless-tools
DEBIAN_FRONTEND=noninteractive apt-get -y --purge autoremove
#sed -i 's/^allow-hotplug \(en.*\)$/auto \1/' /etc/network/interfaces
#sed -i 's/^allow-hotplug en.*$/auto eth0/' /etc/network/interfaces
sed -i 's/^allow-hotplug en.\+$/allow-hotplug eth0/' /etc/network/interfaces
sed -i 's/^iface en.\+ inet dhcp$/iface eth0 inet dhcp/' /etc/network/interfaces
if [ -z "`grep 'GRUB_CMDLINE_LINUX=' /etc/default/grub | sed 's/GRUB_CMDLINE_LINUX=\"\(.*\)"/\1/'`" ]; then
	sed -i 's/^GRUB_CMDLINE_LINUX=""$/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub
else
	sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 \1"/' /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

# work around weird issue with dhclient not being invoked during startup // TODO: Fîx!
echo "[Unit]" > /etc/systemd/system/dhclient.service
echo "Description=Service to invoke dhclient for eth0" >> /etc/systemd/system/dhclient.service
echo "" >> /etc/systemd/system/dhclient.service
echo "[Service]" >> /etc/systemd/system/dhclient.service
echo "Type=simple" >> /etc/systemd/system/dhclient.service
echo "ExecStart=/usr/sbin/dhclient eth0" >> /etc/systemd/system/dhclient.service
echo "After=network-online.target" >> /etc/systemd/system/dhclient.service
echo "Wants=network-online.target" >> /etc/systemd/system/dhclient.service
echo "" >> /etc/systemd/system/dhclient.service
echo "[Install]" >> /etc/systemd/system/dhclient.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/dhclient.service

systemctl enable dhclient.service

# creating mlocate-db
updatedb

# cleanup
rm -f /etc/sudoers.d/99-suppress-sudo-warning
rm -f /home/octoprint/.sudo_as_admin_successful
rm -f /var/lib/sudo/lectured/octoprint