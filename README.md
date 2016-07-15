# Builder of VirtualBox and VMWare VMs with minc-tools

This project is generously supported by [HashiCorp](https://www.hashicorp.com/)
who have graciously provided the cloud service to auto-build and host these VMs.

This is a [packer](https://www.packer.io/) set of build scripts which takes
the Ubuntu ``mini.iso`` file, installs a minimal Lubuntu-core desktop, followed
by installing all of the MINC family of tools as well as R/RStudio for
statistical analysis.

## Usage Instructions

You can find the latest auto-built VMs for download at:
<https://atlas.hashicorp.com/CoBrALab/artifacts/MINC-VM>

These downloads are ``.tar.gz`` files containing importable VMs.

After download, extract with your tool of choice (``tar -xzvf *.tar.gz``),
import the VM into your preferred virtualizer:

For help with importing VMs see:

-   <https://docs.oracle.com/cd/E26217_01/E26796/html/qs-import-vm.html>
-   <http://download.parallels.com/desktop/v5/docs/en/Getting_Started_With_Parallels_Desktop/29714.htm>
-   <https://pubs.vmware.com/workstation-9/index.jsp?topic=%2Fcom.vmware.ws.using.doc%2FGUID-DDCBE9C0-0EC9-4D09-8042-18436DA62F7A.html>

Getting files into and out of the VM is accomplished via the the shared folder
feature. Shared folders are automatically mounted inside ``/media/minc``

For help with shared folders in VirtualBox see <http://www.htpcbeginner.com/setup-virtualbox-shared-folders-linux-windows/>

All software is globally installed and available via the LXTerminal in
the Lubuntu menu.

To install additional software, the use the ``sudo apt`` tools, the user
password is ``minc``

## Tools included

-   [minc-toolkit-v1](https://github.com/BIC-MNI/minc-toolkit)
-   [minc-toolkit-v2](https://github.com/BIC-MNI/minc-toolkit-v2)
-   [pyminc](https://github.com/Mouse-Imaging-Centre/pyminc)
-   [minc-stuffs](https://github.com/Mouse-Imaging-Centre/minc-stuffs)
-   [R](https://www.r-project.org/)
-   [RStudio](https://www.rstudio.com)
-   [RMINC](https://github.com/Mouse-Imaging-Centre/RMINC)
-   [brain-view2](https://github.com/Mouse-Imaging-Centre/brain-view2)
-   [pyezminc](https://github.com/BIC-MNI/pyezminc)
-   [itksnap 3.4.0 with MINC support](https://github.com/vfonov/itksnap3)
-   [mni.cortical.statistics](https://github.com/BIC-MNI/mni.cortical.statistics)
