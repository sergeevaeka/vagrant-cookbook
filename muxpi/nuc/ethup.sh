#!/bin/bash
DUT_IP="$1"
n=1 
max=5
delay=50
while true; do
   ping -c 1 -W 1 $DUT_IP && break || {
     if [[ $n -lt $max ]]; then
       echo "Command failed. Attempt $n/$max:"
       ((n++))
       sleep $delay;
     else
       echo "The command has failed after $n attempts."
       exit 1
     fi
  }
done
echo "Ethernet is up"
