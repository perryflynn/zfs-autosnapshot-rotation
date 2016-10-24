#!/bin/bash

##
# original code by aleonard:
# http://andyleonard.com/2010/04/07/automatic-zfs-snapshot-rotation-on-freebsd/
#
# 07/17/2011 - ertug: made it compatible with zfs-fuse which doesn't have .zfs directories
# 10/24/2016 - cblechert: more checks, timestamps in snapshotname, many small changes
##


# Parse arguments
DIR=$(dirname "$0")
SCRIPT=$(basename "$0")
TARGET=$1
SNAP=$2
COUNT=$3

# Calculated stuff
TSTAMP=$(date "+%Y%m%d-%H%M%S")

# Function to display usage
usage() {
    echo
    echo "$SCRIPT: Take and rotate snapshots on a ZFS file system"
    echo
    echo "  Usage:"
    echo "  $SCRIPT target snap_name count"
    echo
    echo "  target:    name of ZFS file system to act on"
    echo "  snap_name: Base name for snapshots, to be followed by a '.' and"
    echo "             an integer indicating relative age of the snapshot"
    echo "  count:     Number of snapshots in the snap_name.number format to"
    echo "             keep at one time.  Newest snapshot ends in '.0'."
    echo
    exit 1
}

# Must run as root
if [ ! "$(id -u)" == "0" ]; then
    echo "Must run as root!"
    exit 1
fi

# Path to ZFS executable:
ZFS=$(which zfs)

if [ ! -x "$ZFS" ]; then
    echo "zfs exexutable not found!";
    exit 1
fi

# Tank exists
if [ ! "$(zfs list -H -t filesystem,volume | grep -P "^$TARGET\t" | wc -l)" -eq 1 ]; then
    echo "Target tank does not exist!"
    usage
fi

# Basic argument checks:
if ! [[ $COUNT =~ ^[0-9]+$ ]]; then
    echo "count must be a integer!"
    usage
fi

# Snapshotname
if ! [[ $SNAP =~ ^[a-z0-9\-]+$ ]]; then
    echo "Allowed characters for snapshot name: a-z, 0-9, -"
    usage
fi

# No more arguments
if [ ! -z $4 ] ; then
    echo "This script requires exactly 3 arguments!"
    usage
fi

# Securiy check for snap counter
if [ ! "$COUNT" -ge 0 ]; then
    echo "count must be greater than or equal to 0"
    exit 1
fi

# List all snapshots
ALLSNAPS=$($ZFS list -H -t snapshot -d 1 "$TARGET" | awk '{print $1}'| grep -P "@$SNAP-[0-9]{8}-[0-9]{6}$" | sort)

# Calculate number of "old" snapshots
if [ $COUNT -gt 0 ]; then
    COUNT=$(($COUNT-1))
fi

OLDSNAPS=$(echo -e "$ALLSNAPS" | head -n -$COUNT)
NUMOLD=$(echo -e "$OLDSNAPS" | wc -l)

# Clean up oldest snapshot:
if [ $NUMOLD -gt 0 ]; then
    echo "Delete old snapshots"
    for (( I=1; I<=$NUMOLD; I++ )); do
        OLDSNAP=$(echo -e "$OLDSNAPS" | tail -n +$I | head -n 1)
        echo "[$I/$NUMOLD] Delete $OLDSNAP"
        $ZFS destroy -r "$OLDSNAP"
    done
    echo
fi

# Create new snapshot:
NEWSNAP="${TARGET}@${SNAP}-${TSTAMP}"
echo "Create new snapshot $NEWSNAP"
$ZFS snapshot -r "$NEWSNAP"

echo "Done"

echo
zfs list -t all -r -o name,creation,used,avail,usedsnap "$TARGET"
echo

exit 0

