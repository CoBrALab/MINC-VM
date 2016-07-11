#!/bin/bash
set -e
set -x

printenv

cd /tmp

export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y build-essential gdebi-core r-base r-base-dev \
    r-recommended git openssh-server htop imagemagick wget libssl-dev \
    libcurl4-gnutls-dev ed libopenblas-dev python2.7 python-scikits-learn \
    libvtk5-dev python-vtk python-dev zlib1g-dev cython

wget --progress=dot:mega $minc_toolkit_v2
wget --progress=dot:mega $minc_toolkit_v1

wget --progress=dot:mega $bic_mni_models
wget --progress=dot:mega $beast_library

wget --progress=dot:mega $rstudio

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
( cd minc-stuffs && ./autogen.sh && ./configure && make && make install && python2.7 setup.py install )

#Install RMINC (and dependencies)
cat <<-EOF | R --vanilla --quiet
install.packages("devtools", repos='https://cloud.r-project.org/')
library(devtools)
#install_url("https://github.com/Mouse-Imaging-Centre/RMINC/archive/v1.4.2.0.tar.gz", dependencies=TRUE, repos='https://cloud.r-project.org/')
install_github("Mouse-Imaging-Centre/RMINC", dependencies=TRUE, repos='https://cloud.r-project.org/')
quit()
EOF
