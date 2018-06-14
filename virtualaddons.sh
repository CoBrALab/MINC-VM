#!/bin/bash
set -eu
set -x

export DEBIAN_FRONTEND=noninteractive

#Prerequisites
apt update
apt install -y virtualbox-guest-dkms virtualbox-guest-x11 virtualbox-guest-utils

#Add user to premission to access virtualbox drive
addgroup --system vboxsf || true
usermod -a -G vboxsf minc
