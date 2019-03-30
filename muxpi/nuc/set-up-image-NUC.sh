#!/bin/bash

# Copyright (C) 2019 Luxoft Sweden AB
#
# Permission to use, copy, modify, and/or distribute this software for
# any purpose with or without fee is hereby granted, provided that the
# above copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR
# BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
# SOFTWARE.
#
# For further information see LICENSE
#
# This script downloads, flashes the image and tests it on NUC. 
# This script must be run on muxpi.
#
# Usage: 
# $ ./set-up-image-NUC.sh [neptune]
# The default image to use is the minimal image. If you want to run the neptune image
# use the option 'neptune'.


set -e

#If you want to run the neptune image, run `./set-up-image_NUC.sh neptune`
NEPTUNE_IMAGE="$2"
DUT_IP="$1"

HOME="/home/muxpi"
IMAGES="${HOME}/images"

# delete the image folder with old images
rm -rf $IMAGES

#The url for the latest successful nightly build.
VARIANT_MINIMAL="core-image-pelux-minimal-dev-intel-corei7-64"
URL_MINIMAL="https://pelux.io/jenkins/job/pelux-manifests_NIGHTLY/lastSuccessfulBuild/artifact/artifacts_intel/$VARIANT_MINIMAL*/*zip*/artifacts_intel.zip"

VARIANT_NEPTUNE="core-image-pelux-qtauto-neptune-dev-intel-corei7-64"
URL_NEPTUNE="https://pelux.io/jenkins/job/pelux-manifests_NIGHTLY/lastSuccessfulBuild/artifact/artifacts_intel-qtauto/$VARIANT_NEPTUNE*/*zip*/artifacts_intel-qtauto.zip"

VARIANT="core-image-pelux-minimal-dev-intel-corei7-64"
URL=""
if [ "$NEPTUNE_IMAGE" == neptune ]; then
   VARIANT=$VARIANT_NEPTUNE
   URL=$URL_NEPTUNE
else 
   VARIANT=$VARIANT_MINIMAL
   URL=$URL_MINIMAL
fi

mkdir -p $IMAGES

wget -nv $URL -P $IMAGES
if [ $? == 0 ]; then
   echo "Image downloaded"
fi
set +e

unzip $IMAGES/*.zip -d$IMAGES
if [ $?==0 ]; then
       echo "File unziped without errors"
else
       echo"Eror during unzip"
       exit
fi

mv $IMAGES/$VARIANT* $IMAGES/$VARIANT
if [ $? == 0 ]; then
       echo "rename the file success"
else 
       echo "fail rename the file"
       exit
fi
set -e
echo "{\"${VARIANT}\":\"\"}" > $HOME/map.json
echo "Json map is ready. Compressing the downloaded image... "
cd $IMAGES
tar -czvf $VARIANT.tar.gz $VARIANT
# fota requires the card device to be flashed, the json map which contains
# the image and partitions, and finally the compressed image on tar.gz
stm -ts
fota -card /dev/sda -map $HOME/map.json $IMAGES/$VARIANT.tar.gz 
if [ $? == 0 ];then
        echo "Image '${VARIANT} successfully flashed using fota"
fi
# reboot the dut
stm -ts
stm -dut   
# stm -m 30s -tick 
# time for flashing
cd /home/muxpi/scripts

#while ! ping -c 1 -W 1  $DUT_IP; do
   # echo "Waiting for  ${DUT_IP} - network interface might be down..."
  #  sleep 1
#done

./ethup.sh $DUT_IP
scp  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /home/muxpi/scripts/validation-NUC.sh root@$DUT_IP:/home
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$DUT_IP "/home/validation-NUC.sh"



