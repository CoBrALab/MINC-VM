#!/bin/bash
set -eu
set -x

export DEBIAN_FRONTEND=noninteractive

if [[ "$PACKER_BUILDER_TYPE" == virtualbox* ]]; then
  #Prerequisites
  apt update
  apt install -y dkms

  #Mount virtualbox CD and install addons
  mkdir -p /mnt
  mount /dev/sr1 /mnt
  /mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions
  rm -rf /tmp/VBoxGuestAdditions
  umount /mnt

  #Add user to premission to access virtualbox drive
  usermod -a -G vboxsf minc
fi
