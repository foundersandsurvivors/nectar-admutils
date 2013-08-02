nectar-admutils/vdb-initialise documentation
============================================

Purpose
-------

The use case is to minimise the tedium in restarting Nectar Research Cloud instances using second disks, which are not-persistent across restarts.

Description
-----------

On the Nectar research cloud, additional disk volumes are not persistent across restarts. 

These scripts partially automate using a second non-persistent volume on the Nectar research cloud (permnissions are NOT restored).

The scripts (tested on Ubuntu 12.04.2) are:
 * vdb-save.sh : save the contents of the existing /data to S3 container $HOSTNAME_vdb.
 * vdb.sh      : create/format as ext4 the volume /dev/vdb1, mounted on /data, and restore saved S3 container $HOSTNAME_vdb
 * shutdown    : replaces the normal shutdown with a reminder to run vdb-save.sh

After a system restart, the vdb.sh script will automatically recreate, format and restore volume /dev/sdb and restore data from the S3 container. Before a system shutdown, run vdb-save.sh to save /data to S3. 

These scripts are far from perfect (do not do permissions) but are useful at least to me.

Limitations
-----------

S3 download does not restore permissions, so I use an additional script manually to reapply 
required permissions to the contents of /data after S3 restoration depending on specific requirements.


Warning and requirements
------------------------

These scripts were developed on a Ubuntu 12.04 system and use the bash shell. YMMV on other systems. 

Please review, modify and test as required for your own requirements.

################################################### IMPORTANT ##################################################
 * Scripts assume the environment variable $HOSTNAME is set.
 * Scripts assume a mountpoint of /data for the volume /dev/vdb formatted in a single partition as ext4.
   * all contents will be backed up EXCEPT the directory /data/scratch
 * Scripts assume an S3 container named $HOSTNAME_vdb will be used to save/restore the contents of /data.
 * Scripts assume "swift" is installed and working (a python client for S3).
################################################################################################################

The scripts:
  * /home/ubuntu/ec2keys/openrc.sh 
  * /home/ubuntu/ec2keys/ec2rc.sh
are sourced. 

Consult the Nectar support site for more information on these scripts and getting swift working:
 * https://support.rc.nectar.org.au/technical_guides/interfaces/python-swiftclient.html
 * https://support.rc.nectar.org.au/technical_guides/credentials_tech.html

Installation instructions
-------------------------

You need root access.

git clone https://github.com/foundersandsurvivors/nectar-admutils.git
to anywhere convenient.

1. sudo mv /sbin/shutdown shutdown-kill-data-sdb
2. Copy the 3 scripts from the nectar-admutils repo into /usr/local/sbin and set permissions: 
   * shutdown 
   * vdb-save.sh 
   * vdb.sh 
Set permissions:
<pre>
    chown root:root shutdown vdb-save.sh vdb.sh
    chmod 700 shutdown vdb-save.sh vdb.sh
</pre>


This optional step moves/renames the standard system shutdown script so that you are reminded to run vdb-save.sh before shutting down and vdb.sh after restart.

Usage
-----

Assuming scripts have been installed into /usr/local/sbin.

On a VM which does NOT already have a second volume mounted on /dev/vdb:

1. Creating/restoring a 2nd volume: vdb.sh
------------------------------------------

    sudo vdb.sh

Sample output of running this script on host named "smstest1". The host has just been restarted and vdb does not exist:

    root@smstest2: ~ # df -k
    Filesystem     1K-blocks    Used Available Use% Mounted on
    /dev/vda        10321208 4718000   5078920  49% /
    udev             2021020       8   2021012   1% /dev
    tmpfs             810024     224    809800   1% /run
    none                5120       0      5120   0% /run/lock
    none             2025056       0   2025056   0% /run/shm

    root@smstest2: ~ # vdb.sh
    -- /usr/local/sbin/vdb.sh Formatting /dev/vdb and mounting on /data...

    Command (m for help): Partition type:
       p   primary (1 primary, 0 extended, 3 free)
       e   extended
    Select (default p): Partition number (1-4, default 2): Partition 1 is already defined.  Delete it before re-adding it.

    Command (m for help): Command (m for help): Command (m for help): The partition table has been altered!

    Calling ioctl() to re-read partition table.
    Syncing disks.
    mke2fs 1.42 (29-Nov-2011)
    Filesystem label=
    OS type: Linux
    Block size=4096 (log=2)
    Fragment size=4096 (log=2)
    Stride=0 blocks, Stripe width=0 blocks
    1966080 inodes, 7864064 blocks
    393203 blocks (5.00%) reserved for the super user
    First data block=0
    Maximum filesystem blocks=4294967296
    240 block groups
    32768 blocks per group, 32768 fragments per group
    8192 inodes per group
    Superblock backups stored on blocks:
            32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
            4096000

    Allocating group tables: done
    Writing inode tables: done
    Creating journal (32768 blocks): done
    Writing superblocks and filesystem accounting information: done

    OS_TENANT_ID=******
    OS_TENANT_NAME=*******

    -- Restoring container smstest2_vdb
    bx/xml/vjs/latest/ClydeI_1830_M212_c31a_b4a360.27_vjs_tei.xml [headers 0.619s, total 0.667s, 0.477s MB/s]
    .... etc .....

    -- Mountpoint /data restored, it contains:
    total 32
    drwxr-xr-x  5 root root  4096 Aug  2 12:10 .
    drwxr-xr-x 24 root root  4096 Aug  2 12:02 ..
    drwxr-xr-x  3 root root  4096 Aug  2 12:10 backup
    drwxr-xr-x  5 root root  4096 Aug  2 12:10 bx
    drwx------  2 root root 16384 Aug  2 12:09 lost+found


2. Saving contents of /data to s3: vdb-save.sh
----------------------------------------------

    sudo vdb-save.sh

Sample output of running this script on host named "smstest1":

    root@smstest1: ~ # vdb-save.sh
    /dev/vdb1 /data ext4 rw 0 0
    -- Exists: /dev/vdb1 /data ext4 rw 0 0
    -- making /data/00ls-laR-data.txt

    -- Before: swift containe [smstest1_vdb] holds:
    00ls-laR-data.txt
    00readme.txt
    backup/smstest1.etc.tgz
    backup/smstest1.home.tgz
    backup/smstest1.root.tgz
    backup/smstest1.usr.local.tgz

    -- Saving all in mountpoint /data to swift container smstest1_vdb

    -- swift upload to container[smstest1_vdb] 00ls-laR-data.txt 00readme.txt backup
    00ls-laR-data.txt
    00readme.txt
    backup/smstest1.root.tgz
    backup/smstest1.etc.tgz
    backup/smstest1.usr.local.tgz
    backup/smstest1.home.tgz

    -- After: swift list smstest1_vdb
    00ls-laR-data.txt
    00readme.txt
    backup/smstest1.etc.tgz
    backup/smstest1.home.tgz
    backup/smstest1.root.tgz
    backup/smstest1.usr.local.tgz


3. Shutdown
-----------

Follow the instructions given in the new shutdown script:

    sudo shutdown -r now

Will provide these instructions:

    ######################################################################################
    # Before shutdown please save contents of /data on /dev/vdb1
    #    SAVE: sudo /usr/local/sbin/vdb-save.sh
    #    SHUTDOWN: sudo /usr/local/sbin/shutdown-kill-data-sdb -r now
    #    RESTORE: (after restart): sudo /usr/local/sbin/vdb.sh
    ######################################################################################

To REALLY shutdown, after you have run vdb-save.sh:

    sudo /usr/local/sbin/shutdown-kill-data-sdb -r now

--- 
Enjoy!
sms 2013-08-02
