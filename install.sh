#!/bin/bash

# Installation script for WMBusMeters Plugin
# Will be executed during installation and updates

ARGV0=$0    # Zero argument is shell command
PTEMPDIR=$1 # First argument is temp folder during install
PSHNAME=$2  # Second argument is Plugin-Name for scripts etc.
PDIR=$3     # Third argument is Plugin installation folder
PVERSION=$4 # Fourth argument is Plugin version
LBHOMEDIR=$5 # Fifth argument is LoxBerry home directory
PTEMPPATH=$6 # Sixth argument is full temp path during install

# Load LoxBerry environment - try multiple possible paths
if [ -f "$LBHOMEDIR/libs/bashlib/loxberry_system.sh" ]; then
    . $LBHOMEDIR/libs/bashlib/loxberry_system.sh
elif [ -f "$LBHOMEDIR/system/bashlib/loxberry_system.sh" ]; then
    . $LBHOMEDIR/system/bashlib/loxberry_system.sh
fi

# Define plugin paths - LoxBerry provides these after sourcing
PCONFIG=$LBPCONFIG/$PDIR
PDATA=$LBPDATA/$PDIR
PLOG=$LBPLOG/$PDIR
PBIN=$LBPBIN/$PDIR
PHTML=$LBPHTML/$PDIR
PTMPL=$LBPTMPL/$PDIR

# Create logfile
LOGFILE=$PLOG/install.log
mkdir -p $PLOG
touch $LOGFILE
exec > >(tee -a $LOGFILE) 2>&1

echo "<INFO> Installation script started for $PSHNAME"
echo "<INFO> Plugin directory: $PDIR"
echo "<INFO> LoxBerry home: $LBHOMEDIR"
echo "<INFO> Temp directory: $PTEMPDIR"
echo "<INFO> Config directory will be: $PCONFIG"
echo "<INFO> Data directory will be: $PDATA"
echo "<INFO> Binary directory will be: $PBIN"
echo "<INFO> Log directory will be: $PLOG"

# Create necessary directories
echo "<INFO> Creating plugin directories..."
mkdir -p $PCONFIG
mkdir -p $PDATA
mkdir -p $PBIN
mkdir -p $PLOG

# Set permissions
chown -R loxberry:loxberry $PCONFIG
chown -R loxberry:loxberry $PDATA
chown -R loxberry:loxberry $PBIN
chmod -R 775 $PCONFIG $PDATA $PBIN

echo "<INFO> ============================================"
echo "<INFO> WMBusMeters Plugin Installation - Phase 1"
echo "<INFO> ============================================"
echo "<INFO>"
echo "<WARN> WMBusMeters requires root access to install system packages."
echo "<WARN> After this plugin installation completes, please run:"
echo "<WARN>"
echo "<WARN>   sudo /opt/loxberry/data/plugins/wmbusmeters/setup-wmbusmeters.sh"
echo "<WARN>"
echo "<INFO> This will install WMBusMeters from the official Debian repository."
echo "<INFO>"

# Create setup script for user to run with sudo
cat > $PDATA/setup-wmbusmeters.sh << 'EOFSETUP'
#!/bin/bash
# WMBusMeters Setup Script - Run with sudo

set -e

echo "========================================="
echo "WMBusMeters Installation"
echo "========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run with sudo"
    echo "Usage: sudo /opt/loxberry/data/plugins/wmbusmeters/setup-wmbusmeters.sh"
    exit 1
fi

PDATA="/opt/loxberry/data/plugins/wmbusmeters"

echo "Step 1: Adding WMBusMeters repository..."
if [ ! -f /etc/apt/sources.list.d/wmbusmeters.list ]; then
    echo "deb http://download.opensuse.org/repositories/home:/weetmuts/Debian_12/ /" > /etc/apt/sources.list.d/wmbusmeters.list
    wget -qO - https://download.opensuse.org/repositories/home:/weetmuts/Debian_12/Release.key | apt-key add - 2>/dev/null || true
    echo "Repository added"
else
    echo "Repository already exists"
fi

echo ""
echo "Step 2: Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

echo ""
echo "Step 3: Installing wmbusmeters..."
apt-get install -y wmbusmeters

if command -v wmbusmeters &> /dev/null; then
    VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    BINPATH=$(which wmbusmeters)
    echo ""
    echo "SUCCESS!"
    echo "  Version: $VERSION"
    echo "  Binary: $BINPATH"
    
    # Save for web interface
    echo "$BINPATH" > "$PDATA/wmbusmeters_bin_path.txt"
    chown loxberry:loxberry "$PDATA/wmbusmeters_bin_path.txt"
else
    echo "ERROR: Installation failed"
    exit 1
fi

echo ""
echo "Step 4: Configuring system..."
mkdir -p /var/log/wmbusmeters
chown loxberry:loxberry /var/log/wmbusmeters
chmod 775 /var/log/wmbusmeters
usermod -a -G dialout loxberry
systemctl stop wmbusmeters 2>/dev/null || true
systemctl disable wmbusmeters 2>/dev/null || true

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo "Configure WMBusMeters via LoxBerry web interface"
echo ""
EOFSETUP

chmod +x $PDATA/setup-wmbusmeters.sh
echo "<OK> Setup script created: $PDATA/setup-wmbusmeters.sh"

# Check if already installed
if command -v wmbusmeters &> /dev/null; then
    CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<OK> wmbusmeters already installed: $CURRENT_VERSION"
    echo "<INFO> Binary at: $WMBUSMETERS_BIN"
    echo "$WMBUSMETERS_BIN" > $PDATA/wmbusmeters_bin_path.txt
else
    echo "<WARN> wmbusmeters not installed yet"
    echo "NOT_INSTALLED" > $PDATA/wmbusmeters_bin_path.txt
fi

# Final status check
if command -v wmbusmeters &> /dev/null; then
    INSTALLED_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<OK> WMBusMeters ready: $INSTALLED_VERSION"
    echo "<OK> Binary location: $WMBUSMETERS_BIN"
else
    echo "<INFO> WMBusMeters not yet installed"
    echo "<INFO> Run the setup script to complete installation:"
    echo "<INFO> sudo $PDATA/setup-wmbusmeters.sh"
    WMBUSMETERS_BIN="NOT_INSTALLED"
fi

# Create default configuration
echo "<INFO> Creating default configuration at $PCONFIG/wmbusmeters.conf"
cat > $PCONFIG/wmbusmeters.conf << 'EOF'
# WMBusmeters Configuration File
# See https://github.com/wmbusmeters/wmbusmeters for documentation

loglevel=normal
device=auto:t1
donotprobe=/dev/ttyAMA0
logtelegrams=false
format=json
meterfiles=/var/log/wmbusmeters/meter_readings
meterfilesaction=append
logfile=/var/log/wmbusmeters/wmbusmeters.log

# Example meter configuration (uncomment and adjust):
# name=MyWaterMeter
# type=multical21
# id=12345678
# key=00112233445566778899AABBCCDDEEFF
EOF

if [ -f "$PCONFIG/wmbusmeters.conf" ]; then
    echo "<OK> Configuration file created successfully"
    ls -la $PCONFIG/wmbusmeters.conf
else
    echo "<FAIL> Failed to create configuration file"
    exit 1
fi

# Save binary location for web interface
echo "$WMBUSMETERS_BIN" > $PDATA/wmbusmeters_bin_path.txt
echo "<INFO> Binary path saved to: $PDATA/wmbusmeters_bin_path.txt"

# Create systemd service template file (to be installed via web interface with proper permissions)
CONFPATH="$PCONFIG/wmbusmeters.conf"
cat > $PDATA/wmbusmeters.service.template << EOFSERVICE
[Unit]
Description=WMBus Meters Service
After=network.target
Documentation=https://github.com/wmbusmeters/wmbusmeters

[Service]
Type=simple
User=loxberry
Group=loxberry
ExecStart=$WMBUSMETERS_BIN --useconfig=$CONFPATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

echo "<OK> Systemd service template created at: $PDATA/wmbusmeters.service.template"
echo "<INFO> Use web interface to install and manage the service"

# Create log directory for wmbusmeters in plugin data
mkdir -p $PDATA/logs
chmod 775 $PDATA/logs
echo "<OK> Log directory created at: $PDATA/logs"

# Create helper script for easy service management
cat > $PBIN/wmbusmeters-control.sh << 'EOFSCRIPT'
#!/bin/bash
case "$1" in
    start)
        systemctl start wmbusmeters
        ;;
    stop)
        systemctl stop wmbusmeters
        ;;
    restart)
        systemctl restart wmbusmeters
        ;;
    status)
        systemctl status wmbusmeters
        ;;
    logs)
        tail -f /var/log/wmbusmeters/wmbusmeters.log
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOFSCRIPT

chmod +x $PBIN/wmbusmeters-control.sh

# Clean up
cd /tmp
rm -rf wmbusmeters

echo "<OK> Installation completed successfully"
echo "<INFO> Please configure your meters in the web interface"
echo "<INFO> Documentation: https://github.com/wmbusmeters/wmbusmeters"

exit 0
