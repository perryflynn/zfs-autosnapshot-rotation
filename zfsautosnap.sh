#!/bin/bash

##
# original code by aleonard: 
# http://andyleonard.com/2010/04/07/automatic-zfs-snapshot-rotation-on-freebsd/
#
# 07/17/2011 - ertug: made it compatible with zfs-fuse which doesn't have .zfs directories
# 10/24/2016 - cblechert: better checks, timestamps in snapshotname, snapshot only when filsystem has changes
# 03/05/2016 - cblechert: real argument options, usage, cleanup function, bugfixes
##

echo
echo "ZFS-Auto-Snapshot-Rotation"
echo


# Calculated stuff
DIR=$(dirname "$0")
SCRIPT=$(basename "$0")
TSTAMP=$(date "+%Y%m%d-%H%M%S")


# Parse arguments
while [[ $# -ge 1 ]]
do
    key="$1"
    case $key in
        -t|--target)
            TARGET="$2"
            shift # past argument
            ;;
        -n|--name)
            SNAP="$2"
            shift # past argument
            ;;
        -c|--count)
            COUNT="$2"
            shift # past argument
           ;;
        -h|--help)
            HELP=1
            ;;
        --clearall)
            CLEARALL=1
            SPECIALOPS=1
            ;;
        *)
            # unknown option
            ;;
    esac
    shift # past argument or value
done


# Function to display usage
usage() {
    echo
    echo "$SCRIPT: Take and rotate snapshots on a ZFS file system"
    echo
    echo "  Usage:"
    echo "  $SCRIPT [options]"
    echo
    echo "  -t, --target   Required, name of ZFS file system to act on"
    echo "  -n, --name     Required, base name for snapshots,"
    echo "                 followed by the current timestamp"
    echo "  -c, --count    Required, number of snapshots in snap_name.timestamp"
    echo "                 format to keep at one time."
    echo "  --clearall     Delete all snapshots created by $SCRIPT for given target"
    echo "  -h, --help     Print this help"
    echo
    exit 1
}


# Convert bytes into human readable format
nformat() {
    if hash numfmt 2> /dev/null; then
        #numfmt --to=iec-i --suffix=B --padding=7 "$1"
        numfmt --to=iec-i --suffix=B "$1"
    else
        echo $1
    fi
}


# Log line with timestamp
line() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
}


# Help requested
if [ "$HELP" == "1" ]; then
    usage
fi


# Must run as root
if [ ! "$(id -u)" == "0" ]; then
    echo "Must run as root!"
    exit 1
fi


# Path to ZFS executable:
if ! hash zfs 2> /dev/null; then
    echo "zfs exexutable not found!";
    exit 1
fi


# Tank exists
if [ ! "$(zfs list -H -t filesystem,volume | grep -P "^$TARGET\t" | wc -l)" -eq 1 ]; then
    echo "Target tank does not exist!"
    usage
fi


# Optional argument if special operation requested
if [ ! "$SPECIALOPS" == "1" ]; then

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

fi


# Snapshotname
if ! [[ $SNAP =~ ^[a-z0-9\-]+$ ]]; then
    echo "Allowed characters for snapshot name: a-z, 0-9, -"
    usage
fi


#
# Processing
#

line "Begin on \"$TARGET\" for \"$SNAP\""


# Base command to get all snapshots
CMDALLSNAPS="zfs list -H -t snapshot -d 1 \"$TARGET\" | awk '{print \$1}' | grep -P \"@$SNAP-[0-9]{8}-[0-9]{6}$\" | sort"

# Base command to get all "old" snapshots
CMDOLDSNAPS="$CMDALLSNAPS | head -n -$COUNT"

# Number of all snapshots
NUMSNAPS=$(eval "$CMDALLSNAPS | wc -l")
line "$NUMSNAPS snapshots found"


#
# Cleanup all snapshots
#

if [ "$CLEARALL" == 1 ]; then

    line "Cleanup all snapshots"

    if [ "$NUMSNAPS" -gt 0 ]; then

        I=0
        ALLSNAPS=$(eval "$CMDALLSNAPS")
        printf '%s\n' "$ALLSNAPS" | while IFS= read -r SNAP
        do
            I=$(($I+1))
            line "[$I/$NUMSNAPS] Delete snapshot \"$SNAP\""
            zfs destroy -r "$SNAP"
        done

    else
        line "No snapshots found"
    fi


#
# Standard action: create new snapshot
#

else

    # Number of "old" snapshots
    NUMOLD=$(eval "$CMDOLDSNAPS | wc -l")
    line "$NUMOLD old snapshots detected"

    # List of "old" snapshots
    OLDSNAPS=$(eval "$CMDOLDSNAPS")

    # Name of the newest snapshot
    NEWESTSNAPNAME=$(eval "$CMDALLSNAPS | tail -n 1 | cut -d '@' -f 2")
    line "The newest \"$SNAP\" snapshot in \"$TARGET\" is \"$NEWESTSNAPNAME\""

    # Calculate changes
    CHANGESCOUNT=$(zfs list -H -p -t filesystem,volume -o name,written@$NEWESTSNAPNAME | \
        grep -P "^${TARGET}(/[^\s@]+)?\s" | awk '{print $2}' | grep -v "-" | \
        sed ':a;N;$!ba;s/\n/+/g' | sed 's/^/0+/g' | bc)

    # Start snapshot process only, when changes available
    if [ -z "$CHANGESCOUNT" ] || [ $CHANGESCOUNT -gt 0 ]; then

        # First snapshot or changes?
        if [ -z "$CHANGESCOUNT" ]; then
            line "Create first snapshot"
        else
            line "Changes ($(nformat "$CHANGESCOUNT")) since last snapshot detected"
        fi

        # Clean up "old" snapshot:
        if [ $NUMOLD -gt 0 ]; then
            for (( I=1; I<=$NUMOLD; I++ )); do

                OLDSNAP=$(echo -e "$OLDSNAPS" | tail -n +$I | head -n 1)
                line "[$I/$NUMOLD] Delete old snapshot \"$OLDSNAP\""
                zfs destroy -r "$OLDSNAP"

            done
        fi

        # Create new snapshot:
        NEWSNAP="${TARGET}@${SNAP}-${TSTAMP}"
        line "Create new snapshot \"$NEWSNAP\""
        zfs snapshot -r "$NEWSNAP"

    else
        line "No changes since last snapshot. Abort."
    fi

fi

line "Done"
