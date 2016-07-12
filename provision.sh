#!/bin/bash
set -e
set -x

cd /tmp

export DEBIAN_FRONTEND=noninteractive

#Enable auto-login
cat <<-EOF >> /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=minc
autologin-user-timeout=0
EOF

apt update
#Command line tools
apt install -y htop nano wget imagemagick
#Build tools and dependencies
apt install -y build-essential gdebi-core \
    git imagemagick libssl-dev cmake autotools-dev automake \
    libcurl4-gnutls-dev ed libopenblas-dev python2.7 python-scikits-learn \
    python-vtk6 libvtk6-dev python-dev zlib1g-dev cython python-setuptools

wget --progress=dot:mega $minc_toolkit_v2
wget --progress=dot:mega $minc_toolkit_v1

wget --progress=dot:mega $bic_mni_models

#Beast models are disabled for now, they're huge
#wget --progress=dot:mega $beast_library

for file in *.deb
do
	gdebi --n $file
done

rm -f *.deb

#Enable minc-toolkit for all users
echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/profile
echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/bash.bashrc

. /opt/minc-itk4/minc-toolkit-config.sh

#Download other packages
wget --progress=dot:mega $pyminc -O pyminc.tar.gz

#Can't use wget because submodule isn't installed
#wget --progress=dot:mega https://github.com/Mouse-Imaging-Centre/minc-stuffs/archive/v0.1.14.tar.gz -O minc-stuffs.tar.gz
git clone --recursive --branch $minc_stuffs https://github.com/Mouse-Imaging-Centre/minc-stuffs.git minc-stuffs

wget --progress=dot:mega $pyezminc -O pyezminc.tar.gz

wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel

#Do this so that we don't need to keep track of version numbers
mkdir pyminc && tar xzf pyminc.tar.gz -C pyminc --strip-components 1
#mkdir minc-stuffs && tar xzf minc-stuffs.tar.gz -C minc-stuffs --strip-components 1
mkdir pyezminc && tar xzf pyezminc.tar.gz -C pyezminc --strip-components 1

#Build and install packages
( cd pyezminc && python2.7 setup.py install )
( cd pyminc && python2.7 setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure --with-build-path=/opt/minc-itk4 && make && make install && python2.7 setup.py install )

rm -rf pyezminc pyminc minc-stuffs

# apt install -y r-base r-base-dev r-recommended
# wget --progress=dot:mega $rstudio
# gdebi --n *.deb
# rm -f *.deb
#Install RMINC (and dependencies)
#cat <<-EOF | R --vanilla --quiet
#install.packages("devtools", repos='https://cloud.r-project.org/', dependencies=TRUE)
#library(devtools)
#install_url("$RMINC", dependencies=TRUE, repos='https://cloud.r-project.org/')
#install_github("Mouse-Imaging-Centre/RMINC", dependencies=TRUE, repos='https://cloud.r-project.org/')
#quit()
#EOF

apt-get -y clean
apt-get -y autoremove
