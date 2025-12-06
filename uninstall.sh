#!/bin/bash

# Uninstallation script for WMBusMeters Plugin
# Will be executed when the plugin is uninstalled

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

# Create logfile
LOGFILE=$LOGDIR/uninstall.log
touch $LOGFILE
exec > >(tee -a $LOGFILE) 2>&1

echo "<INFO> Uninstallation script started for $PLUGINNAME"

# Stop and disable wmbusmeters service
if systemctl is-active --quiet wmbusmeters; then
    echo "<INFO> Stopping wmbusmeters service..."
    systemctl stop wmbusmeters
fi

if systemctl is-enabled --quiet wmbusmeters; then
    echo "<INFO> Disabling wmbusmeters service..."
    systemctl disable wmbusmeters
fi

# Remove systemd service file
if [ -f "/etc/systemd/system/wmbusmeters.service" ]; then
    echo "<INFO> Removing systemd service file..."
    rm -f /etc/systemd/system/wmbusmeters.service
    systemctl daemon-reload
fi

# Ask user if they want to remove wmbusmeters completely
echo "<INFO> Removing wmbusmeters binary..."
if command -v wmbusmeters &> /dev/null; then
    rm -f /usr/bin/wmbusmeters
    rm -f /usr/sbin/wmbusmeters
fi

# Optionally keep configuration and logs
# User can manually delete /var/log/wmbusmeters if needed
echo "<INFO> Keeping configuration backup in /var/log/wmbusmeters"
echo "<INFO> You can manually delete this directory if not needed"

echo "<OK> Uninstallation completed successfully"
exit 0
