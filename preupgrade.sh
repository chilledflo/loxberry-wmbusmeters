#!/bin/bash

# Preupgrade script for WMBusMeters Plugin
# Will be executed before plugin upgrade

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

# Create temp logfile
LOGFILE=$LOGDIR/preupgrade.log
touch $LOGFILE
exec > >(tee -a $LOGFILE) 2>&1

echo "<INFO> Preupgrade script started for $PLUGINNAME"

# Backup current configuration if exists
if [ -f "$PLUGINDIR/config/wmbusmeters.conf" ]; then
    echo "<INFO> Backing up configuration..."
    cp "$PLUGINDIR/config/wmbusmeters.conf" "$PLUGINDIR/config/wmbusmeters.conf.backup"
    echo "<OK> Configuration backed up"
fi

# Stop wmbusmeters service if running
if systemctl is-active --quiet wmbusmeters; then
    echo "<INFO> Stopping wmbusmeters service..."
    systemctl stop wmbusmeters
    echo "<OK> Service stopped"
fi

echo "<OK> Preupgrade completed successfully"
exit 0
