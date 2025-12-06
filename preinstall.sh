#!/bin/bash

# Preinstall script for WMBusMeters Plugin
# Will be executed before installation/update

ARGV0=$0 # Zero argument is shell command
PTEMPDIR=$1 # First argument is temp folder during install
PSHNAME=$2  # Second argument is Plugin-Name for scripts etc.
PDIR=$3     # Third argument is Plugin installation folder
PVERSION=$4 # Fourth argument is Plugin version
LBHOMEDIR=$5 # Fifth argument is LoxBerry home directory
PTEMPPATH=$6 # Sixth argument is full temp path during install

# Read LoxBerry environment
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
. $LBHOMEDIR/libs/bashlib/loxberry_system.sh

PACKAGE=$PSHNAME
PLUGINNAME=$PDIR
LOGDIR=$LBHOMEDIR/log/plugins/$PLUGINNAME
PLUGINDIR=$PTEMPDIR

# Create log directory if not exists
if [ ! -d $LOGDIR ]; then
    mkdir -p $LOGDIR
    chown loxberry:loxberry $LOGDIR
    chmod 775 $LOGDIR
fi

# Create temp logfile
LOGFILE=$LOGDIR/preinstall.log
touch $LOGFILE
exec > >(tee -a $LOGFILE) 2>&1

echo "<INFO> Preinstall script started for $PLUGINNAME"
echo "<INFO> Plugin directory: $PLUGINDIR"

# Check system requirements
echo "<INFO> Checking system requirements..."

# Check if we have enough disk space (min 100MB)
FREESPACE=$(df -m / | awk 'NR==2 {print $4}')
if [ $FREESPACE -lt 100 ]; then
    echo "<ERROR> Not enough disk space. Need at least 100MB free."
    exit 1
fi

echo "<OK> Preinstall checks passed"
exit 0
