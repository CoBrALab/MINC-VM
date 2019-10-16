#!/bin/bash
#set -euo pipefail
set -x

#Prerequisites
apt update
apt install -y build-essential

apt install -y --install-recommends linux-generic-hwe-18.04 xserver-xorg-hwe-18.04 

#Add user to premission to access virtualbox drive
addgroup --system vboxsf || true
usermod -a -G vboxsf minc || true

# Mount the disk image
cd /tmp
mkdir /tmp/isomount
mount -t iso9660 -o loop /home/minc/VBoxGuestAdditions.iso /tmp/isomount

# Install the drivers
/tmp/isomount/VBoxLinuxAdditions.run

/sbin/rcvboxadd quicksetup all

# Cleanup
umount isomount
rm -rf isomount /home/minc/VBoxGuestAdditions.iso

#Final cleanup
apt-get -y clean
apt-get -y --purge autoremove

#Cleanup to ensure extra files aren't packed into VM
cd ~
rm -rf /tmp/provision
rm -f /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*

dd if=/dev/zero of=/zerofillfile bs=1M || true
rm -f /zerofillfile

