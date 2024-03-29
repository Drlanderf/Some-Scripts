#! /bin/bash
# Script developped by Adrien.D from Linuxtricks
# Tested on Linux Mint 20.3 + Ubuntu 22.04 + Debian SID
if [ $(id -u) -ne 0 ]
then
    echo "Script must be run as root"
    exit 1
fi
DISTRIBTYPE=$(egrep ^ID= /etc/os-release | awk -F= '{ print $2 ;}')
if [ "$DISTRIBTYPE" = "linuxmint" ]
then
    DISTRIBTYPE=$(egrep ^ID_LIKE= /etc/os-release | awk -F= '{ print $2 ;}')
fi
#echo "Distribution type : $DISTRIBTYPE"
KERNELUSED=$(uname -r)
KERNELLIST=$(dpkg -l | egrep  ii.*linux-image | awk '{ print $2; }')
KERNELTOREMOVE=""
#echo "########################"
#echo "Kernel list : $KERNELLIST"
for k in $KERNELLIST
do
    if [ "$DISTRIBTYPE" = "ubuntu" ]
    then
        if [ "$k" != "linux-image-generic" -a "$k" != "linux-image-$KERNELUSED" ]
        then
            KERNELTOREMOVE="$k $KERNELTOREMOVE"
        fi
    fi
    if [ "$DISTRIBTYPE" = "debian" ]
    then
        if [ "$k" != "linux-image-amd64" -a "$k" != "linux-image-$KERNELUSED" ]
        then
            KERNELTOREMOVE="$k $KERNELTOREMOVE"
        fi
    fi
done
#echo "Kernel list to remove : $KERNELTOREMOVE"
KERNELVERSIONSTOREMOVE=$(echo $KERNELTOREMOVE | sed -e 's/linux-image-//g')
#echo "Kernel version to remove : $KERNELVERSIONSTOREMOVE"
DPKGKERNELS=""
for v in $KERNELVERSIONSTOREMOVE
do
    if [ "$DISTRIBTYPE" = "ubuntu" ]
    then
        vNOGENERIC=$(echo $v | sed -e 's/-generic//')
        DPKGKERNELS="linux-headers-$v linux-image-$v linux-modules-$v linux-modules-extra-$v linux-headers-$vNOGENERIC $DPKGKERNELS"
    fi
    if [ "$DISTRIBTYPE" = "debian" ]
    then
        vNOARCH=$(echo $v | sed -e 's/-amd64/-common/')
        DPKGKERNELS="linux-headers-$v linux-image-$v linux-modules-$v linux-modules-extra-$v linux-headers-$vNOARCH $DPKGKERNELS"
    fi
done
#echo "Commande dpkg : dpkg --remove $DPKGKERNELS"
#echo "########################"
echo "Distribution type : $DISTRIBTYPE"
echo "Active kernel : $KERNELUSED"
echo "Kernel version to remove : $KERNELVERSIONSTOREMOVE"
if [ -n "$DPKGKERNELS" ]
then
    read -p "Lets go ? Type YES if OK : " ANWSERGO
    if [ "$ANWSERGO" = "YES" ]
    then
        dpkg --remove $DPKGKERNELS
 
        for v in $KERNELVERSIONSTOREMOVE
        do
            rm -rf /lib/modules/$v
            rm -rf /usr/src/linux-headers-$v
            if [ "$DISTRIBTYPE" = "ubuntu" ]
            then
                vNOGENERIC=$(echo $v | sed -e 's/-generic//')
                rm -rf /usr/src/linux-headers-$vNOGENERIC
            fi
            if [ "$DISTRIBTYPE" = "debian" ]
            then
                vNOARCH=$(echo $v | sed -e 's/-amd64/-common/')
                rm -rf /usr/src/linux-headers-$vNOARCH
            fi
        done
    fi
else
    echo "No kernels to remove"
fi