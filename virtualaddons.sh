#!/bin/bash
set -eu
set -x

#Virtualbox addons
mkdir -p /mnt
mount /dev/sr1 /mnt
/mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions
rm -rf /tmp/VBoxGuestAdditions
umount /mnt
