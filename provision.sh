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

#Enable neurodebian
wget -O- http://neuro.debian.net/lists/xenial.us-nh.full > /etc/apt/sources.list.d/neurodebian.sources.list
apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9

#Enable R mirror
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" > /etc/apt/sources.list.d/R.sources.list

apt update
apt -y full-upgrade
apt-get --purge -y autoremove

#Command line tools
apt install -y --no-install-recommends htop nano wget imagemagick
#Build tools and dependencies
apt install -y --no-install-recommends build-essential gdebi-core \
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

wget --progress=dot:mega $generate_deformation_fields -O generate_deformation_fields.tar.gz

wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel

#Do this so that we don't need to keep track of version numbers for build
mkdir pyminc && tar xzvf pyminc.tar.gz -C pyminc --strip-components 1
mkdir pyezminc && tar xzvf pyezminc.tar.gz -C pyezminc --strip-components 1
mkdir generate_deformation_fields && tar xzvf generate_deformation_fields.tar.gz -C generate_deformation_fields  --strip-components 1

#Build and install packages
( cd pyezminc && python2.7 setup.py install )
( cd pyminc && python2.7 setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure --with-build-path=/opt/minc-itk4 && make && make install && python2.7 setup.py install )
( cd generate_deformation_fields && ./autogen.sh && ./configure --with-minc2 --with-build-path=/opt/minc-itk4 && make && make install)
( cd generate_deformation_fields/scripts && python setup.py build_ext --inplace && python setup.py install)

#Cleanup
rm -rf pyezminc* pyminc* minc-stuffs*

#Installing brain-view2
apt install -y --no-install-recommends libcoin80-dev libpcre++-dev qt4-default libqt4-opengl-dev libtool
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

#Purge unneeded packages
apt-get purge $(dpkg -l | tr -s ' ' | cut -d" " -f2 | sed 's/:amd64//g' | grep -e -E '(-dev|-doc)$')

#Install R
apt install -y --no-install-recommends r-base r-base-dev r-recommended lsof

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
install_url("$mni_cortical_statistics")
quit()
EOF

#Remove a hunk of useless packages which seem to be safe to remove
apt-get -y purge printer-driver.* xserver-xorg-video.* xscreensaver.* wpasupplicant wireless-tools .*vdpau.* \
bluez-cups cups-browsed cups-bsd cups-client cups-common cups-core-drivers cups-daemon cups-filters \
cups-filters-core-drivers cups-ppdc cups-server-common linux-headers.* snapd bluez linux-firmware .*sane.* .*ppds.*

apt-get -y clean
apt-get -y autoremove

#Cleanup to ensure extra files aren't packed into VM
cd ~
rm -rf /tmp/provision
rm -f /var/cache/apt/archives/*.deb

dd if=/dev/zero of=/zerofillfile bs=1M || true
rm -f /zerofillfile
