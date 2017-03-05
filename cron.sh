#!/bin/bash

#
# Cron helper script
# Modify the properties and the switch case as you need
# Example:
#
# m h dom mon dow user	command
# 12 2	1 * *	root	/media/files/admin/zfstools/cron.sh --mode monthly 
#

#
# Properties
#

# Prefix for volume names - see snap function
ZFSPREFIX="myraidz/"

# zfsautosnap script
BIN="./zfsautosnap.sh"

# this script name
SCRIPT="$(basename "$0")"


# Switch to script dir
cd "$(dirname "$0")"


#
# Parse arguments
#
while [[ $# -ge 1 ]]
do
    key="$1"
    case $key in
        -m|--mode)
            MODE="$2"
            shift # past argument
            ;;
        -h|--help)
            HELP=1
            ;;
        *)
            # unknown option
            ;;
    esac
    shift # past argument or value
done


# variables from arguments
LOGFILE="/tmp/autosnap-${MODE}.log"


# help
usage() {
    echo "Usage: $SCRIPT --mode [mode]"
    echo
    echo "  -m, --mode   Cron mode: weekly, houly, ..."
    echo "  -h, --help   Print this help"
    echo
    exit 1
}


# Helper function to call autosnap script
snap() {
    TARGET=$1
    NAME=$2
    COUNT=$3
    $BIN -t "${ZFSPREFIX}${TARGET}" -n "asnap${NAME}" -c "$COUNT" >> "$LOGFILE" 2>&1
}


# print help
if [ "$HELP" == "1" ]; then
    usage
fi


#
# Processing
#

cat /dev/null > "$LOGFILE"

case $MODE in

hourly)
    SN="hourly"
    snap "pve" "$SN" 2
    snap "pve-manual" "$SN" 2
    snap "files/nas/home" "$SN" 2
    snap "files/nas/tausch" "$SN" 2
    snap "files/admin" "$SN" 1
    snap "files/seafile-data" "$SN" 2
    ;;

daily)
    SN="daily"
    snap "files/nas/home" "$SN" 2
    snap "files/nas/media" "$SN" 1
    snap "files/nas/tausch" "$SN" 2
    snap "files/seafile-data" "$SN" 1
    snap "files/admin" "$SN" 1
    ;;

weekly)
    SN="weekly"
    snap "files/nas/home" "$SN" 2
    snap "files/nas/tausch" "$SN" 2
    ;;

monthly)
    SN="monthly"
    snap "files/nas/home" "$SN" 2
    snap "files/nas/tausch" "$SN" 2
    snap "files/seafile-data" "$SN" 1
    snap "files/admin" "$SN" 1
    ;;

*)
   echo "No valid mode"
   exit 1
   ;;

esac


exit 0
