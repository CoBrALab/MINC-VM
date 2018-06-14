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
wget -O- http://neuro.debian.net/lists/artful.us-nh.full > /etc/apt/sources.list.d/neurodebian.sources.list

set +e
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xA5D32F012649A5A9
while [ $? -ne 0 ]; do
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xA5D32F012649A5A9
done


#Enable R mirror
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
while [ $? -ne 0 ]; do
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
done

set -e

apt install -y --no-install-recommends software-properties-common apt-transport-https

apt update
apt -y full-upgrade
apt-get --purge -y autoremove

#Command line tools
apt install -y --no-install-recommends htop nano wget imagemagick parallel zram-config
#Build tools and dependencies
apt install -y --no-install-recommends build-essential gdebi-core \
    git imagemagick libssl-dev cmake autotools-dev automake \
    libcurl4-gnutls-dev ed zlib1g-dev libxml2-dev libxslt-dev default-jre \
    zenity

wget --progress=dot:mega https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p /opt/miniconda
OLDPATH=$PATH
export PATH="/opt/miniconda/bin:$PATH"
echo 'source /opt/miniconda/bin/activate' >> /etc/bash.bashrc

rm miniconda.sh

conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda

conda install --yes numpy scipy python-graphviz scikit-image scikit-learn pip cython setuptools
conda install --yes -c simpleitk simpleitk

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
echo '. /opt/minc/1.9.16/minc-toolkit-config.sh' >> /etc/profile
echo 'export PATH=/opt/minc-toolkit-extras/:$PATH' >> /etc/bash.bashrc

#Enable minc-toolkit in this script
set +u
. /opt/minc/1.9.16/minc-toolkit-config.sh
set -u

#Download other packages
wget --progress=dot:mega $pyminc -O pyminc.tar.gz

#Can't use wget because submodule doesn't show up in package
#wget --progress=dot:mega https://github.com/Mouse-Imaging-Centre/minc-stuffs/archive/v0.1.14.tar.gz -O minc-stuffs.tar.gz
git clone --recursive --branch $minc_stuffs https://github.com/Mouse-Imaging-Centre/minc-stuffs.git minc-stuffs

wget --progress=dot:mega $pyezminc -O pyezminc.tar.gz

wget --progress=dot:mega $generate_deformation_fields -O generate_deformation_fields.tar.gz

wget --progress=dot:mega $pydpiper -O pydpiper.tar.gz

wget --progress=dot:mega $bpipe -O bpipe.tar.gz

wget https://raw.githubusercontent.com/andrewjanke/volgenmodel/master/volgenmodel -O /usr/local/bin/volgenmodel

git clone https://github.com/CobraLab/minc-toolkit-extras.git /opt/minc-toolkit-extras

#Do this so that we don't need to keep track of version numbers for build
mkdir pyminc && tar xzvf pyminc.tar.gz -C pyminc --strip-components 1
mkdir pyezminc && tar xzvf pyezminc.tar.gz -C pyezminc --strip-components 1
mkdir generate_deformation_fields && tar xzvf generate_deformation_fields.tar.gz -C generate_deformation_fields  --strip-components 1
mkdir pydpiper && tar xzvf pydpiper.tar.gz -C pydpiper --strip-components 1
mkdir -p /opt/bpipe && tar xzvf bpipe.tar.gz -C /opt/bpipe --strip-components 1 && ln -s /opt/bpipe/bin/bpipe /usr/local/bin/bpipe

#Build and install packages
( cd pyezminc && python setup.py install --mincdir /opt/minc/1.9.16 )
( cd pyminc && python setup.py install )
( cd minc-stuffs && ./autogen.sh && ./configure --with-build-path=/opt/minc/1.9.16 && make && make install && python setup.py install )
( cd generate_deformation_fields && ./autogen.sh && ./configure --with-minc2 --with-build-path=/opt/minc/1.9.16 && make && make install)
( cd generate_deformation_fields/scripts && python setup.py build_ext --inplace && python setup.py install)
( cd pydpiper && python setup.py install)

conda install nipype

pip install https://github.com/pipitone/qbatch/archive/master.zip

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

( cd quarter && cmake . && make && make install )
( cd bicinventor && ./autogen.sh && ./configure --with-build-path=/opt/minc/1.9.16 --with-minc2 && make && make install )
( cd brain-view2 && /usr/bin/qmake MINCDIR=/opt/minc/1.9.16 HDF5DIR=/opt/minc/1.9.16 && make && cp brain-view2 /opt/minc/1.9.16/bin )

rm -rf quarter* bicinventor* brain-view2*

#Install itksnap-MINC
wget $itksnap_minc -O itksnap_minc.tar.gz
tar xzvf itksnap_minc.tar.gz -C /usr/local --strip-components 1
rm -f itksnap_minc.tar.gz

#Purge unneeded packages
apt-get purge $(dpkg -l | tr -s ' ' | cut -d" " -f2 | sed 's/:amd64//g' | grep -e -E '(-dev|-doc)$')

#Install R
#apt install -y --no-install-recommends r-base r-base-dev lsof r-recommended r-cran-batchtools r-cran-dplyr r-cran-tidyr r-cran-lme4 r-cran-shiny \
#    r-cran-gridbase r-cran-gridextra r-cran-r.utils r-cran-rcpp r-cran-doparallel r-cran-rcppparallel r-cran-matrix r-cran-tibble \
#    r-cran-yaml r-cran-visnetwork r-cran-rjson r-cran-dt r-cran-rgl r-cran-plotrix r-bioc-biocinstaller r-bioc-qvalue r-cran-testthat \
#    r-cran-igraph r-cran-devtools r-cran-diagrammer r-cran-downloader r-cran-influencer r-cran-readr r-cran-hms r-cran-rook r-cran-rook \
#    r-cran-xml r-cran-viridis

conda install --yes r r-essentials r-recommended rstudio
conda install --yes gcc_linux-64 gxx_linux-64 gfortran_linux-64 r-acepack r-adgoftest r-aer r-afex r-anomalydetection \
r-ape r-argparse r-assertthat r-backports r-base r-base64enc r-bcp r-bdsmatrix r-bestglm r-bh r-bindr r-bindrcpp r-bit r-bit64 \
r-bitops r-blob r-boot r-bradleyterry2 r-brew r-brglm r-broom r-cairo r-car r-caret r-catools r-cellranger r-checkmate r-chron \
r-class r-cluster r-coda r-codetools r-coin r-colorspace r-commonmark r-config r-copula r-crayon r-crosstalk r-ctv r-curl \
r-cvst r-cvtools r-data.table r-dbi r-dbplyr r-ddalpha r-debugme r-deoptimr r-desc r-devtools r-diagrammer r-dichromat \
r-digest r-dimred r-domc r-doparallel r-downloader r-dplyr r-drr r-dt r-dygraphs r-e1071 r-essentials r-estimability \
r-evaluate r-feather r-findpython r-forcats r-foreach r-forecast r-foreign r-formatr r-formattable r-formula r-fracdiff \
r-functional r-fwdselect r-gdata r-getopt r-ggplot2 r-ggvis r-gistr r-git2r r-glmnet r-glue r-gmp r-gower r-gplots \
r-gridbase r-gridextra r-grpreg r-gsl r-gsw r-gtable r-gtools r-haven r-hexbin r-highcharter r-highr r-hmisc r-hms \
r-htmltable r-htmltools r-htmlwidgets r-httpuv r-httr r-hunspell r-igraph r-influencer r-inline r-ipred r-irdisplay \
r-irkernel r-irlba r-iterators r-janeaustenr r-jpeg r-jsonlite r-kernlab r-kernsmooth r-knitr r-kohonen r-labeling \
r-lahman r-lars r-lattice r-latticeextra r-lava r-lazyeval r-leaflet r-leaps r-lintr r-lme4 r-lmertest r-lmtest \
r-logging r-lsmeans r-lubridate r-magrittr r-manipulate r-mapproj r-maps r-maptools r-markdown r-mass r-matrix \
r-matrixmodels r-memoise r-mgcv r-microbenchmark r-mime r-miniui r-minqa r-mlmrev r-mnormt r-modelmetrics r-modelr \
r-modeltools r-mongolite r-multcomp r-munsell r-mvtnorm r-networkd3 r-nlme r-nloptr r-nlp r-nmf r-nnet r-numderiv \
r-nycflights13 r-oce r-odbc r-openssl r-packrat r-pbdzmq r-pbkrtest r-pcapp r-perm r-pkgconfig r-pkgmaker r-pki \
r-plm r-plogr r-plyr r-png r-polspline r-praise r-proc r-processx r-prodlim r-profilemodel r-profvis r-proto \
r-pryr r-pspline r-psych r-purrr r-quadprog r-quantmod r-quantreg r-qvcalc r-r.methodss3 r-r.oo r-r.utils r-r6 \
r-randomforest r-rappdirs r-raster r-rbokeh r-rcolorbrewer r-rcpp r-rcpparmadillo r-rcppeigen r-rcpproll r-rcurl \
r-readr r-readxl r-recipes r-registry r-rematch r-repr r-reshape r-reshape2 r-reticulate r-rex r-rgexf \
r-rgl r-rhive r-rjava r-rjdbc r-rjson r-rjsonio r-rlang r-rlist r-rmarkdown r-rmr2 r-rms r-rngtools r-robustbase \
r-rocr r-rodbc r-rook r-roxygen2 r-rpart r-rprojroot r-rsconnect r-rserve r-rsqlite r-rstan r-rstudioapi \
r-rversions r-rvest r-rzmq r-sandwich r-scales r-seacarb r-selectr r-sf r-sfsmisc r-shiny \
r-shinybs r-shinycssloaders r-shinydashboard r-shinyjs r-shinysky r-shinythemes r-slam r-snowballc r-sourcetools \
r-sp r-sparklyr r-sparsem r-spatial r-stabledist r-stanheaders r-stringdist r-stringi r-stringr r-strucchange \
r-survival r-tensorflow r-testit r-testthat r-tfruns r-th.data r-threejs r-tibble r-tidyr r-tidyselect r-tidytext \
r-tidyverse r-tilegramsr r-timedate r-tm r-tokenizers r-tseries r-ttr r-udunits2 r-units r-urca r-uuid r-vars \
r-vgam r-viridis r-viridislite r-visnetwork r-weatherdata r-whisker r-withr r-xlsx r-xlsxjars r-xml r-xml2 r-xtable r-xts r-yaml r-zoo

#Install rstudio
#wget --progress=dot:mega $rstudio
#gdebi --n *.deb
#rm -f *.deb

export MINC_PATH=/opt/minc/1.9.16
#export PATH=$OLDPATH

cat <<-EOF | R --vanilla --quiet
library(devtools)
install_url("$RMINC", repos = 'http://cloud.r-project.org/', dependencies=TRUE)
install_url("$mni_cortical_statistics", repos = 'https://cloud.r-project.org/', dependencies=TRUE)
quit()
EOF

#Remove a hunk of useless packages which seem to be safe to remove
apt-get -y purge printer-driver.* xserver-xorg-video.* xscreensaver.* wpasupplicant wireless-tools .*vdpau.* \
bluez-cups cups-browsed cups-bsd cups-client cups-common cups-core-drivers cups-daemon cups-filters \
cups-filters-core-drivers cups-ppdc cups-server-common linux-headers.* snapd bluez linux-firmware .*sane.* .*ppds.*

apt-get -y clean
apt-get -y --purge autoremove

#Cleanup to ensure extra files aren't packed into VM
cd ~
rm -rf /tmp/provision
rm -f /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*

dd if=/dev/zero of=/zerofillfile bs=1M || true
rm -f /zerofillfile
