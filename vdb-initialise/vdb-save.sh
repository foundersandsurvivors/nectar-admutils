#!/bin/bash
. /etc/environment
CONTAINER="${HOSTNAME}_vdb"
VOL="/dev/vdb"
MOUNTPOINT="/data"
EXISTS=`grep $VOL /etc/mtab`
echo $EXISTS
if [ "$EXISTS" == "" ]; then
    echo "-- Volume $VOL not mounted, cannot save"
    exit 1
else
    echo "-- Exists: $EXISTS"
fi

# see if we can restore from swift
if [ -f /home/ubuntu/ec2keys/openrc.sh ]; then
   . /home/ubuntu/ec2keys/openrc.sh
   . /home/ubuntu/ec2keys/ec2rc.sh
   printenv|grep TENANT_NAME
   POSTIT=`swift list $CONTAINER | grep "not found"`
   echo $POSTIT
   if [ "$POSTIT" == "" ]; then
      echo ""
      echo "-- Before: swift containe [$CONTAINER] holds:"
      swift list $CONTAINER
   else
      echo ""
      echo "-- Creating swift container: [$CONTAINER]"
      swift post $CONTAINER
      echo "-- Populate the swift container [$CONTAINER] with data to restore"
   fi
fi

echo ""
echo "-- Saving all in mountpoint $MOUNTPOINT to swift container $CONTAINER"
cd $MOUNTPOINT
CONTENTS=`ls |grep -v 'lost+found'|grep -v scratch|xargs`
echo ""
echo "############################################################################ upload begin at `date`"
echo "-- swift upload --changed $CONTAINER $CONTENTS"
swift upload --changed $CONTAINER $CONTENTS
echo "############################################################################ upload finished at `date`"
echo ""
echo "-- After: swift list $CONTAINER"
swift list $CONTAINER


