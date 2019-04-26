#!/bin/bash

DBPATH=$1
DBPORT=$2
NETDEVICE=$3

if [ -z "$NETDEVICE" ]
then
  NETDEVICE="eth0"
fi

# Parse the ip address of this node on Gemini
DBHOST=`ip addr show $NETDEVICE | grep -Eo '(addr:)?([0-9]*\.){3}[0-9]*' | head -n1`

echo "$DBHOST" > $DBPATH/db.hostname

echo "Hopefully ulimit is 32k..."
ulimit -n

./launch_amongod.sh $DBPATH $DBPORT --launch 2> mongodb.launcher.err 1> mongodb.launcher.out
