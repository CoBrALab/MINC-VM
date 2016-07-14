#!/bin/bash
set -e
set -x

mkdir -p /tmp/provision

cd /tmp/provision

#Make sure apt doesn't complain
export DEBIAN_FRONTEND=noninteractive

#Enable auto-login
cat <<-EOF > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=minc
autologin-user-timeout=0
user-session=Lubuntu
EOF

#Enable R mirror
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
apt-add-repository -y "deb https://cran.rstudio.com/bin/linux/ubuntu xenial/"

apt update
apt -y full-upgrade
apt-get --purge -y autoremove

#Command line tools
apt install -y htop nano wget imagemagick
#Build tools and dependencies
apt install -y build-essential gdebi-core \
    git imagemagick libssl-dev cmake autotools-dev automake \
    libcurl4-gnutls-dev ed libopenblas-dev python2.7 python-scikits-learn \
    python-vtk6 libvtk6-dev python-dev zlib1g-dev cython python-setuptools

#Download external debs
wget --progress=dot:mega $minc_toolkit_v2
wget --progress=dot:mega $minc_toolkit_v1
wget --progress=dot:mega $bic_mni_models

#Beast models are disabled for now, they're huge
#wget --progress=dot:mega $beast_library

#Install downloaded debs
for file in *.deb
do
	gdebi --n $file
done

#Cleanup debs
rm -f *.deb

#Enable minc-toolkit for all users
echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/profile
echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/bash.bashrc

#Enable minc-toolkit in this script
. /opt/minc-itk4/minc-toolkit-config.sh

#Download other packages
wget --progress=dot:mega $pyminc -O pyminc.tar.gz

#Can't use wget because submodule doesn't show up in package
#wget --progress=dot:mega https://github.com/Mouse-Imaging-Centre/minc-stuffs/archive/v0.1.14.tar.gz -O minc-stuffs.tar.gz
git clone --recursive --branch $minc_stuffs https://github.com/Mouse-Imaging-Centre/minc-stuffs.git minc-stuffs

wget --progress=dot:mega $pyezminc -O pyezminc.tar.gz

wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel

#Do this so that we don't need to keep track of version numbers for build
mkdir pyminc && tar xzvf pyminc.tar.gz -C pyminc --strip-components 1
mkdir pyezminc && tar xzvf pyezminc.tar.gz -C pyezminc --strip-components 1

#Build and install packages
( cd pyezminc && python2.7 setup.py install )
( cd pyminc && python2.7 setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure --with-build-path=/opt/minc-itk4 && make && make install && python2.7 setup.py install )

#Cleanup
rm -rf pyezminc* pyminc* minc-stuffs*

#Installing brain-view2
apt install -y libcoin80-dev libpcre++-dev qt4-default
wget $quarter -O quarter.tar.gz
wget $bicinventor -O bicinventor.tar.gz
wget $brain_view2 -O brain-view2.tar.gz
mkdir quarter && tar xzvf quarter.tar.gz -C quarter --strip-components 1
mkdir bicinventor && tar xzvf bicinventor.tar.gz -C bicinventor --strip-components 1
mkdir brain-view2 && tar xzvf brain-view2.tar.gz -C brain-view2 --strip-components 1

( cd quarter && cmake . && make && make install )
( cd bicinventor && ./autogen.sh && ./configure --with-build-path=/opt/minc-itk4 --with-minc2 && make && make install )
( cd brain-view2 && qmake MINCDIR=/opt/minc-itk4 HDF5DIR=/opt/minc-itk4 && make && cp brain-view2 /opt/minc-itk4/bin )

rm -rf quarter* bicinventor* brain-view2*

#Install itksnap-MINC
wget $itksnap_minc -O itksnap_minc.tar.gz
tar xzvf itksnap_minc.tar.gz -C /usr/local --strip-components 1
rm -f itksnap_minc.tar.gz

#Install R
apt install -y r-base r-base-dev r-recommended

#Install rstudio
wget --progress=dot:mega $rstudio
gdebi --n *.deb
rm -f *.deb

#Install RMINC (and dependencies)
cat <<-EOF | R --vanilla --quiet
source("https://bioconductor.org/biocLite.R")
library(BiocInstaller)
install.packages("devtools", repos = 'https://cloud.r-project.org', dependencies=TRUE)
library(devtools)
install_url("$RMINC", repos = 'https://cloud.r-project.org', dependencies=TRUE)
quit()
EOF

apt-get -y clean
apt-get -y autoremove

#Cleanup to ensure extra files aren't packed into VM
cd ~
rm -rf /tmp/provision
rm -f /var/cache/apt/archives/*.deb
