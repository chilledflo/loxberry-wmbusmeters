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
echo "<INFO> Temp directory: $PTEMPDIR"
echo "<INFO> Temp path: $PTEMPPATH"
echo "<INFO> Plugin name: $PSHNAME"
echo "<INFO> Plugin folder: $PDIR"
echo "<INFO> Plugin version: $PVERSION"
echo "<INFO> LoxBerry home: $LBHOMEDIR"
echo "<INFO> Current working directory: $(pwd)"

# Check system requirements
echo "<INFO> Checking system requirements..."

# Check if we have enough disk space (min 100MB)
FREESPACE=$(df -m / | awk 'NR==2 {print $4}')
echo "<INFO> Free disk space: ${FREESPACE}MB"
if [ $FREESPACE -lt 100 ]; then
    echo "<ERROR> Not enough disk space. Need at least 100MB free."
    exit 1
fi

# Try to find the actual temp path and fix permissions
echo "<INFO> Searching for install.sh..."
INSTALL_SCRIPT=""
if [ -f "$PTEMPPATH/install.sh" ]; then
    INSTALL_SCRIPT="$PTEMPPATH/install.sh"
elif [ -f "$LBHOMEDIR/system/tmpfs/$PTEMPDIR/install.sh" ]; then
    INSTALL_SCRIPT="$LBHOMEDIR/system/tmpfs/$PTEMPDIR/install.sh"
elif [ -f "/tmp/$PTEMPDIR/install.sh" ]; then
    INSTALL_SCRIPT="/tmp/$PTEMPDIR/install.sh"
fi

if [ -n "$INSTALL_SCRIPT" ]; then
    echo "<OK> install.sh found at: $INSTALL_SCRIPT"
    ls -la "$INSTALL_SCRIPT"
    
    # Make all shell scripts executable
    echo "<INFO> Setting execute permissions on shell scripts..."
    chmod +x "$PTEMPPATH"/*.sh 2>/dev/null || true
    
    echo "<INFO> Permissions after chmod:"
    ls -la "$INSTALL_SCRIPT"
    echo "<OK> Execute permissions set"
else
    echo "<ERROR> install.sh NOT found in any expected location"
    echo "<INFO> Searching filesystem..."
    find /tmp -name "install.sh" -type f 2>/dev/null | head -5
    exit 1
fi

echo "<OK> Preinstall checks passed"
exit 0
