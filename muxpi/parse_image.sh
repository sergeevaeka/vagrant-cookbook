#!/bin/bash
set -e
ARCHVARIANT="$1"
DUT_IP="$2"
NEPTUNE_IMAGE="$3"

MUXPI="$HOME/muxpi"
IMAGES="$MUXPI/images"


rm -rf $IMAGES

VARIANT_MINIMAL="core-image-pelux-minimal-dev"
URL_MINIMAL="https://pelux.io/jenkins/job/pelux-manifests_NIGHTLY/lastSuccessfulBuild/artifact/artifacts_$ARCHVARIANT/$VARIANT_MINIMAL*/*zip*/artifacts_$ARCHVARIANT.zip"

VARIANT_NEPTUNE="core-image-pelux-qtauto-neptune-dev"
URL_NEPTUNE="https://pelux.io/artifacts/core-image-pelux-qtauto-neptune-dev-intel-corei7-64.wic"

VARIANT=""
URL=""
if [ "$NEPTUNE_IMAGE" == neptune ]; then
   VARIANT=$VARIANT_NEPTUNE
   URL=$URL_NEPTUNE
else
   VARIANT=$VARIANT_MINIMAL
   URL=$URL_MINIMAL
fi

if [ "$ARCHVARIANT" == "" ]; then
   echo "Please specify architecture. It can be 'intel' or 'rpi'"
   exit
fi

mkdir -p $MUXPI
mkdir -p $IMAGES
#------------------------------------------
echo "Downloading \"$VARIANT\"..."

wget --quiet $URL -P $IMAGES 
if [ $? == 0 ]; then
   echo "Image downloaded"
fi

#set +e
#7z x $IMAGES/*.zip -o$IMAGES 
#set -e

mv $IMAGES/$VARIANT* $IMAGES/$VARIANT

echo "Compresing \"$VARIANT\"..."
(cd $IMAGES; tar -czf $VARIANT.tar.gz $VARIANT)
if [ $? == 0 ]; then
   echo "Image has finished compressing"
fi

echo "{\"${VARIANT}\":\"\"}" > $MUXPI/map.json
echo "Json map is ready"



scp -i ~/.ssh/build_slave_key $IMAGES/$VARIANT.tar.gz muxpi@172.31.173.165:~/artifacts
scp -i ~/.ssh/build_slave_key $MUXPI/map.json muxpi@172.31.173.165:~/artifacts
ssh -i ~/.ssh/build_slave_key muxpi@172.31.173.165 "~/scripts/set-up-image-NUC.sh $DUT_IP $VARIANT.tar.gz $NEPTUNE_IMAGE"
