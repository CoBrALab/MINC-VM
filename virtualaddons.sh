#!/bin/bash
#set -euo pipefail
set -x

#Prerequisites
apt update
apt install -y build-essential

#Add user to premission to access virtualbox drive
addgroup --system vboxsf || true
usermod -a -G vboxsf minc || true

# Mount the disk image
cd /tmp
mkdir /tmp/isomount
mount -t iso9660 -o loop /home/minc/VBoxGuestAdditions.iso /tmp/isomount

# Install the drivers
/tmp/isomount/VBoxLinuxAdditions.run

# Cleanup
umount isomount
rm -rf isomount /home/minc/VBoxGuestAdditions.iso
