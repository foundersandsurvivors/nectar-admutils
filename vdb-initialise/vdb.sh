#!/bin/bash
. /etc/environment
CONTAINER="${HOSTNAME}_vdb"
VOL="/dev/vdb"
MOUNTPOINT="/data"
EXISTS=`grep $VOL /etc/mtab`
echo $EXISTS
if [ "$EXISTS" == "" ]; then
    echo "-- $0 Formatting $VOL and mounting on $MOUNTPOINT..."
    for i in $VOL;do
echo "n
p
1


w
"|fdisk $i;mkfs.ext4 ${i}1;mount ${i}1 $MOUNTPOINT;done

else
    echo "-- Exists: $EXISTS"
fi

# see if we can restore from swift
if [ -f /home/ubuntu/ec2keys/openrc.sh ]; then
   . /home/ubuntu/ec2keys/openrc.sh
   printenv|grep TENANT
   POSTIT=`swift list $CONTAINER | grep "not found"`
   echo $POSTIT
   if [ "$POSTIT" == "" ]; then
      cd $MOUNTPOINT
      echo "-- Restoring container $CONTAINER"
      swift download $CONTAINER
      echo "-- Mountpoint $MOUNTPOINT restored, it contains:"
      ls -la $MOUNTPOINT
   else
      echo "-- Creating container $CONTAINER"
      swift post $CONTAINER
      echo "-- Populate the container $CONTAINER with data to restore"
   fi
fi

