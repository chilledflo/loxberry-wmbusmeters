#!/bin/bash

# Postinstall script for WMBusMeters Plugin
# Runs AFTER the plugin is installed, with elevated privileges via sudoers

ARGV0=$0
PTEMPDIR=$1
PSHNAME=$2
PDIR=$3
PVERSION=$4
LBHOMEDIR=$5
PTEMPPATH=$6

echo "<INFO> ========================================"
echo "<INFO> Postinstall: Installing WMBusMeters"
echo "<INFO> ========================================"

# Check if wmbusmeters is already installed
if command -v wmbusmeters &> /dev/null; then
    VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "<OK> WMBusMeters already installed: $VERSION"
    exit 0
fi

# Install wmbusmeters using the install script in /opt/loxberry/bin/plugins/wmbusmeters
INSTALL_SCRIPT="/opt/loxberry/bin/plugins/wmbusmeters/install-wmbusmeters.sh"

if [ -f "$INSTALL_SCRIPT" ]; then
    echo "<INFO> Running installation script with sudo..."
    sudo "$INSTALL_SCRIPT"
    
    if command -v wmbusmeters &> /dev/null; then
        VERSION=$(wmbusmeters --version 2>&1 | head -n1)
        echo "<OK> WMBusMeters successfully installed: $VERSION"
    else
        echo "<FAIL> Installation failed"
    fi
else
    echo "<WARN> Installation script not found: $INSTALL_SCRIPT"
fi

echo "<INFO> ========================================"
exit 0
