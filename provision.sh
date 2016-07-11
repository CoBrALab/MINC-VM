#!/bin/bash
set -e
set -x

printenv

cd /tmp

export DEBIAN_FRONTEND=noninteractive

apt update
apt install build-essential gdebi-core r-base r-base-dev \
    r-recommended git openssh-server htop imagemagick wget libssl-dev \
    libcurl4-gnutls-dev ed openblas-dev python2.7 python-scikits-learn \
    libvtk5-dev python-vtk python-dev zlib-devel cython

wget --progress=dot:mega http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.9.11-20160202-Ubuntu_15.04-x86_64.deb
wget --progress=dot:mega http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.0.08-20160205-Ubuntu_15.04-x86_64.deb

wget --progress=dot:mega http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/bic-mni-models-0.1.1-20120421.deb
wget --progress=dot:mega http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/beast-library-1.1.0-20121212.deb

wget --progress=dot:mega https://download1.rstudio.org/rstudio-0.99.902-amd64.deb

for file in *.deb
do
	gdebi --n $file
done

rm -f *.deb

echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/profile
echo '. /opt/minc-itk4/minc-toolkit-config.sh' >> /etc/bash.bashrc

. /opt/minc-itk4/minc-toolkit-config.sh

wget --progress=dot:mega https://github.com/Mouse-Imaging-Centre/pyminc/archive/v0.4.tar.gz -O pyminc.tar.gz

#Can't use wget because submodule isn't installed
#wget --progress=dot:mega https://github.com/Mouse-Imaging-Centre/minc-stuffs/archive/v0.1.14.tar.gz -O minc-stuffs.tar.gz
git clone --recursive --branch v0.1.14 https://github.com/Mouse-Imaging-Centre/minc-stuffs.git minc-stuffs

wget --progress=dot:mega https://github.com/BIC-MNI/pyezminc/archive/release-1.1.00.tar.gz -O pyezminc.tar.gz

wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel

#Do this so that we don't need to keep track of version numbers
mkdir pyminc && tar xzf pyminc.tar.gz -C pyminc --strip-components 1
#mkdir minc-stuffs && tar xzf minc-stuffs.tar.gz -C minc-stuffs --strip-components 1
mkdir pyezminc && tar xzf pyezminc.tar.gz -C pyezminc --strip-components 1

( cd pyezminc && python2.7 setup.py install )
( cd pyminc && python2.7 setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure && make && make install && python2.7 setup.py install )

cat <<-EOF | R --vanilla --quiet
install.packages("devtools", repos='https://cloud.r-project.org/')
library(devtools)
#install_url("https://github.com/Mouse-Imaging-Centre/RMINC/archive/v1.4.2.0.tar.gz", dependencies=TRUE, repos='https://cloud.r-project.org/')
install_github("Mouse-Imaging-Centre/RMINC", dependencies=TRUE, repos='https://cloud.r-project.org/')
quit()
EOF
