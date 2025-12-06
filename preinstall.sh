#!/bin/bash

# Preinstall script for WMBusMeters Plugin
# Will be executed before installation/update

ARGV0=$0 # Zero argument is shell command
ARGV1=$1 # First argument is folder path
ARGV2=$2 # Second argument is plugin name

# Read LoxBerry environment
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
. $LBHOMEDIR/libs/bashlib/loxberry_system.sh

PACKAGE=$ARGV2
PLUGINNAME=${PACKAGE}
LOGDIR=$LBHOMEDIR/log/plugins/$PLUGINNAME
PLUGINDIR=$ARGV1

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
