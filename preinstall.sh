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

# Read LoxBerry environment - try multiple possible paths
if [ -f "$LBHOMEDIR/libs/bashlib/loxberry_log.sh" ]; then
    . $LBHOMEDIR/libs/bashlib/loxberry_log.sh
    . $LBHOMEDIR/libs/bashlib/loxberry_system.sh
elif [ -f "$LBHOMEDIR/system/bashlib/loxberry_log.sh" ]; then
    . $LBHOMEDIR/system/bashlib/loxberry_log.sh
    . $LBHOMEDIR/system/bashlib/loxberry_system.sh
fi

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

echo "<INFO> WMBusMeters will be installed by postinstall.sh (after plugin setup)"

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
    
    # WORKAROUND: LoxBerry doesn't seem to call install.sh automatically
    # so we call it directly from preinstall.sh
    echo "<INFO> WORKAROUND: Calling install.sh directly from preinstall..."
    echo "<INFO> Parameters: PTEMPDIR=$PTEMPDIR PSHNAME=$PSHNAME PDIR=$PDIR PVERSION=$PVERSION LBHOMEDIR=$LBHOMEDIR PTEMPPATH=$PTEMPPATH"
    
    # Execute install.sh with the same parameters
    if [ -x "$INSTALL_SCRIPT" ]; then
        echo "<INFO> Executing: $INSTALL_SCRIPT $PTEMPDIR $PSHNAME $PDIR $PVERSION $LBHOMEDIR $PTEMPPATH"
        "$INSTALL_SCRIPT" "$PTEMPDIR" "$PSHNAME" "$PDIR" "$PVERSION" "$LBHOMEDIR" "$PTEMPPATH"
        INSTALL_RESULT=$?
        if [ $INSTALL_RESULT -eq 0 ]; then
            echo "<OK> install.sh completed successfully"
        else
            echo "<FAIL> install.sh failed with exit code $INSTALL_RESULT"
            exit $INSTALL_RESULT
        fi
    else
        echo "<ERROR> install.sh is not executable"
        exit 1
    fi
else
    echo "<ERROR> install.sh NOT found in any expected location"
    echo "<INFO> Searching filesystem..."
    find /tmp -name "install.sh" -type f 2>/dev/null | head -5
    exit 1
fi

echo "<OK> Preinstall checks passed"
exit 0
