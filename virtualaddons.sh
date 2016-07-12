#!/bin/bash
set -eu
set -x

#Prerequisites
apt update
apt install -y dkms

#Mount virtualbox CD and install addons
mkdir -p /mnt
mount /dev/sr1 /mnt
/mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions
rm -rf /tmp/VBoxGuestAdditions
umount /mnt
