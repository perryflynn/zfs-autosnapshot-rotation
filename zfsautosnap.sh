#!/bin/bash

##
# original code by aleonard:
# http://andyleonard.com/2010/04/07/automatic-zfs-snapshot-rotation-on-freebsd/
#
# 07/17/2011 - ertug: made it compatible with zfs-fuse which doesn't have .zfs directories
# 10/24/2016 - cblechert: more checks, timestamps in snapshotname, snapshot only when filsystem has changes
##

echo
echo "ZFS-Auto-Snapshot-Rotation"
echo

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

# Log line with timestamp
line() {
    echo "[$(date "+%Y%m%d %H:%M:%S")] $1"
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

# Count must be numeric
if ! [[ $COUNT =~ ^[0-9]+$ ]]; then
    echo "count must be a integer!"
    usage
fi

# Count must be greater than or equals to zero
if [ ! "$COUNT" -ge 0 ]; then
    echo "count must be greater than or equal to 0"
    exit 1
fi

# Delete one more than specified -> space for the new snapshot
if [ $COUNT -gt 0 ]; then
    COUNT=$(($COUNT-1))
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

#
# Processing
#

line "Begin on \"$TARGET\" for \"$SNAP\""

# Base command to get all snapshots
CMDALLSNAPS="$ZFS list -H -t snapshot -d 1 \"$TARGET\" | awk '{print \$1}' | grep -P \"@$SNAP-[0-9]{8}-[0-9]{6}$\" | sort"

# Base command to get all "old" snapshots
CMDOLDSNAPS="$CMDALLSNAPS | head -n -$COUNT"

# Number of all snapshots
NUMSNAPS=$(eval "$CMDALLSNAPS | wc -l")
line "$NUMSNAPS snapshots found"

# Number of "old" snapshots
NUMOLD=$(eval "$CMDOLDSNAPS | wc -l")
line "$NUMOLD old snapshots detected"

# List of "old" snapshots
OLDSNAPS=$(eval "$CMDOLDSNAPS")

# Name of the newest snapshot
NEWESTSNAPNAME=$(eval "$CMDALLSNAPS | tail -n 1 | cut -d '@' -f 2")
line "The newest \"$SNAP\" snapshot in \"$TARGET\" is \"$NEWESTSNAPNAME\""

# Generate zfs diff commands
CHANGESCMD=$($ZFS list -H -t snapshot | grep -P "^${TARGET}(/[^\s@]+)?@${NEWESTSNAPNAME}\s" | awk '{print $1}' | sed "s#^\([^@]*\)\(.*\)#$ZFS diff \"\1\2\" \"\1\"#" | sed ':a;N;$!ba;s/\n/; /g')

# Count changes since last snapshot
CHANGESCOUNT=$(eval "$CHANGESCMD" | wc -l)

# Start snapshot process only, when changes available
if [ $CHANGESCOUNT -gt 0 ]; then

    line "Changes since last snapshot detected"

    # Clean up "old" snapshot:
    if [ $NUMOLD -gt 0 ]; then
        for (( I=1; I<=$NUMOLD; I++ )); do

            OLDSNAP=$(echo -e "$OLDSNAPS" | tail -n +$I | head -n 1)
            line "[$I/$NUMOLD] Delete old snapshot \"$OLDSNAP\""
            $ZFS destroy -r "$OLDSNAP"

        done
    fi

    # Create new snapshot:
    NEWSNAP="${TARGET}@${SNAP}-${TSTAMP}"
    echo "Create new snapshot \"$NEWSNAP\""
    $ZFS snapshot -r "$NEWSNAP"

else

    line "No changes since last snapshot. Abort."

fi

line "Done"
