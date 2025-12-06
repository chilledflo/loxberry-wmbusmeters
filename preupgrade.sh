#!/bin/bash

# Preupgrade script for WMBusMeters Plugin
# Will be executed before plugin upgrade

ARGV0=$0 # Zero argument is shell command
PTEMPDIR=$1 # First argument is temp folder during install
PSHNAME=$2  # Second argument is Plugin-Name for scripts etc.
PDIR=$3     # Third argument is Plugin installation folder
PVERSION=$4 # Fourth argument is Plugin version
LBHOMEDIR=$5 # Fifth argument is LoxBerry home directory
PTEMPPATH=$6 # Sixth argument is full temp path during install

# Read LoxBerry environment - try multiple possible paths
if [ -f "$LBHOMEDIR/libs/bashlib/loxberry_system.sh" ]; then
    . $LBHOMEDIR/libs/bashlib/loxberry_system.sh
elif [ -f "$LBHOMEDIR/system/bashlib/loxberry_system.sh" ]; then
    . $LBHOMEDIR/system/bashlib/loxberry_system.sh
fi

PACKAGE=$PSHNAME
PLUGINNAME=$PDIR
LOGDIR=$LBHOMEDIR/log/plugins/$PLUGINNAME
PLUGINDIR=$PTEMPDIR

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
