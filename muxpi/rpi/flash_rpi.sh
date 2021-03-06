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
# This flashes the image and tests it on RPI. 
# This script must be run on muxpi.
# Usage: 
# $ ./flash_rpi.sh DUT_IP IMAGE_NAME
#    DUP_IP = a string with IP, can be an empty string
#    IMAGE_NAME = a string with the name of the variant

set -e

DUT_IP="$1"
IMAGE_NAME="$2"
HOMEPATH="/home/muxpi"
IMAGES="$HOME/images"

# The url for the latest successful nightly build.

fota_armv7 -card /dev/sda -map $HOME/artifacts/map.json $HOMEPATH/artifacts/$IMAGE_NAME
if [ $? == 0 ];then
   echo "Image '${IMAGE_NAME}' successfully flashed using fota"
fi

echo "Image is set up. Booting up RPI ..."

cd /home/muxpi/scripts
stm_armv7 -dut

$HOMEPATH/scripts/ethup.sh $DUT_IP
    
scp  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /home/muxpi/scripts/validation.sh root@$DUT_IP:/home	
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$DUT_IP "/home/validation.sh"

stm_armv7 -ts
stm_armv7 -dut
