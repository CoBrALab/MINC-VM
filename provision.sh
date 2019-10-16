#!/bin/bash
set -euo pipefail
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
wget -O- http://neuro.debian.net/lists/bionic.us-nh.full  > /etc/apt/sources.list.d/neurodebian.sources.list

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA5D32F012649A5A9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

apt install -y --no-install-recommends software-properties-common apt-transport-https

apt-add-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/"
add-apt-repository -y ppa:marutter/c2d4u3.5

apt update
apt -y full-upgrade
apt-get --purge -y autoremove

#Essentials
apt install -y build-essential

#Command line tools
apt install -y --no-install-recommends htop nano wget imagemagick parallel zram-config debconf

#Build tools and dependencies
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt install -y --no-install-recommends build-essential gdebi-core \
  git imagemagick libssl-dev cmake autotools-dev automake \
  ed zlib1g-dev libxml2-dev libxslt-dev openjdk-8-jre \
  zenity libcurl4-openssl-dev bc gawk libxkbcommon-x11-0 \
  ttf-mscorefonts-installer bc

wget --progress=dot:mega https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p /opt/miniconda
rm miniconda.sh

OLDPATH=$PATH
export PATH="/opt/miniconda/bin:$PATH"
echo 'source /opt/miniconda/bin/activate' >> /home/minc/.bashrc

conda config --append channels conda-forge
conda config --append channels bioconda
conda config --append channels simpleitk

conda install --yes numpy scipy python-graphviz scikit-image scikit-learn pip cython setuptools simpleitk nipype

#Download external debs
wget --progress=dot:mega $minc_toolkit_v2
wget --progress=dot:mega $minc_toolkit_v1
wget --progress=dot:mega $bic_mni_models

wget --progress=dot:mega $beast_library

#Install downloaded debs
for file in *.deb
do
  gdebi --n $file
done

#Cleanup debs
rm -f *.deb

#Enable minc-toolkit for all users
echo '. /opt/minc/1.9.17/minc-toolkit-config.sh' >> /home/minc/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/minc/1.9.17/lib' >> /home/minc/.bashrc
echo 'export PATH=/opt/minc-toolkit-extras/:$PATH' >> /home/minc/.bashrc

#Enable minc-toolkit in this script, need to escape error checking
set +u
. /opt/minc/1.9.17/minc-toolkit-config.sh
set -u

#Download other packages
wget --progress=dot:mega $pyminc -O pyminc.tar.gz
wget --progress=dot:mega $minc_stuffs -O minc-stuffs.tar.gz
wget --progress=dot:mega $pyezminc -O pyezminc.tar.gz
wget --progress=dot:mega $minc2_simple -O minc2-simple.tar.gz
wget --progress=dot:mega $generate_deformation_fields -O generate_deformation_fields.tar.gz
wget --progress=dot:mega $pydpiper -O pydpiper.tar.gz
wget --progress=dot:mega $bpipe -O bpipe.tar.gz
wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel
git clone https://github.com/CobraLab/minc-toolkit-extras.git /opt/minc-toolkit-extras

#Do this so that we don't need to keep track of version numbers for build
mkdir -p pyminc && tar xzvf pyminc.tar.gz -C pyminc --strip-components 1
mkdir -p minc-stuffs && tar xzvf minc-stuffs.tar.gz -C minc-stuffs --strip-components 1
mkdir -p generate_deformation_fields && tar xzvf generate_deformation_fields.tar.gz -C generate_deformation_fields --strip-components 1
mkdir -p pyezminc && tar xzvf pyezminc.tar.gz -C pyezminc --strip-components 1
mkdir -p minc2-simple &&  tar xzvf minc2-simple.tar.gz -C minc2-simple --strip-components 1
mkdir -p pydpiper && tar xzvf pydpiper.tar.gz -C pydpiper --strip-components 1
mkdir -p /opt/bpipe && tar xzvf bpipe.tar.gz -C /opt/bpipe --strip-components 1 && ln -s /opt/bpipe/bin/bpipe /usr/local/bin/bpipe

#Build and install packages
( cd pyezminc && python setup.py install --mincdir /opt/minc/1.9.17 )
( cd minc2-simple && python python/setup.py install && mkdir -p build && cd build && cmake -DCMAKE_INSTALL_PREFIX=${MINC_TOOLKIT} .. && make -j4 install )
( cd pyminc && python setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure --with-build-path=/opt/minc/1.9.17 && make -j4 install && python setup.py install )
( cd generate_deformation_fields && ./autogen.sh && ./configure --with-minc2 --with-build-path=/opt/minc/1.9.17 && make -j4 install)
( cd generate_deformation_fields/scripts && python setup.py build_ext --inplace && python setup.py install)
( cd pydpiper && python setup.py install)

pip install qbatch

#Cleanup
rm -rf pyezminc* pyminc* minc-stuffs* generate_deformation_fields* pydpiper* bpipe*

#Installing brain-view2
apt install -y --no-install-recommends libcoin80-dev libpcre++-dev qt4-default libqt4-opengl-dev libtool
wget $quarter -O quarter.tar.gz
wget $bicinventor -O bicinventor.tar.gz
wget $brain_view2 -O brain-view2.tar.gz
mkdir quarter && tar xzvf quarter.tar.gz -C quarter --strip-components 1
mkdir bicinventor && tar xzvf bicinventor.tar.gz -C bicinventor --strip-components 1
mkdir brain-view2 && tar xzvf brain-view2.tar.gz -C brain-view2 --strip-components 1

( cd quarter && cmake . && make -j4 install )
( cd bicinventor && ./autogen.sh && ./configure --with-build-path=/opt/minc/1.9.17 --prefix=/opt/minc/1.9.17 --with-minc2 && make -j4 install )
( cd brain-view2 && /usr/bin/qmake-qt4 MINCDIR=/opt/minc/1.9.17 HDF5DIR=/opt/minc/1.9.17 INVENTORDIR=/opt/minc/1.9.17 && make -j4 && cp brain-view2 /opt/minc/1.9.17/bin )

rm -rf quarter* bicinventor* brain-view2*

#Install itksnap-MINC
#wget $itksnap_minc -O itksnap_minc.deb
#gdebi -n itksnap_minc.deb
#rm -f itksnap_minc.deb

#Install R
apt install -y --no-install-recommends r-base r-base-dev lsof r-recommended r-cran-batchtools r-cran-dplyr r-cran-tidyr r-cran-lme4 r-cran-shiny \
  r-cran-gridbase r-cran-gridextra r-cran-r.utils r-cran-rcpp r-cran-doparallel r-cran-rcppparallel r-cran-matrix r-cran-tibble \
  r-cran-yaml r-cran-visnetwork r-cran-rjson r-cran-dt r-cran-rgl r-cran-plotrix r-bioc-biocinstaller r-bioc-qvalue r-cran-testthat \
  r-cran-igraph r-cran-devtools r-cran-diagrammer r-cran-downloader r-cran-influencer r-cran-readr r-cran-hms r-cran-rook r-cran-rook \
  r-cran-xml r-cran-viridis r-cran-data.tree


#Install rstudio
wget --progress=dot:mega ${rstudio}
gdebi --n *.deb
rm -f *.deb

export MINC_PATH=/opt/minc/1.9.17
export PATH=${OLDPATH}

cat <<-EOF | Rscript --vanilla -
r = getOption("repos")
r["CRAN"] = 'http://cloud.r-project.org/'
options(repos = r)
options(Ncpus = 4)
rm(r)
library(devtools)
res <- install_url("$RMINC", args = "--configure-args='--with-build-path=/opt/minc/1.9.17'", dependencies=TRUE, upgrade=FALSE)
if(isFALSE(res)) stop("Couldn't install RMINC")
res <- install_url("$mni_cortical_statistics", dependencies=TRUE, upgrade=FALSE)
if(isFALSE(res)) stop("Couldn't install mni_cortical_statistics")
res <- install_github("$MRIcrotome", dependencies=TRUE, upgrade=FALSE)
if(isFALSE(res)) stop("Couldn't install mni_cortical_statistics")
EOF

#Purge unneeded packages
apt-get purge $(dpkg -l | tr -s ' ' | cut -d" " -f2 | sed 's/:amd64//g' | grep -e -E '(-dev|-doc)$')

#Remove a hunk of useless packages which seem to be safe to remove
apt-get -y purge printer-driver.* xscreensaver.* wpasupplicant wireless-tools .*vdpau.* \
  bluez-cups cups-browsed cups-bsd cups-client cups-common cups-core-drivers cups-daemon cups-filters \
  cups-filters-core-drivers cups-ppdc cups-server-common linux-headers.* snapd bluez linux-firmware .*sane.* .*ppds.*

apt-get -y clean
apt-get -y --purge autoremove
