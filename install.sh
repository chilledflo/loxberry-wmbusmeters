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

echo "<INFO> Installing WMBusMeters..."

# Check if already installed system-wide
if command -v wmbusmeters &> /dev/null; then
    CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<OK> wmbusmeters already installed: $CURRENT_VERSION"
    echo "<INFO> Binary at: $WMBUSMETERS_BIN"
    echo "$WMBUSMETERS_BIN" > $PDATA/wmbusmeters_bin_path.txt
else
    # WMBusMeters will be installed by postinstall.sh
    echo "<INFO> WMBusMeters not yet installed"
    echo "<INFO> Will be installed automatically by postinstall.sh"
    echo "<INFO> Installation script created at: $PBIN/install-wmbusmeters.sh"
    echo "PENDING" > $PDATA/wmbusmeters_bin_path.txt
    WMBUSMETERS_BIN="PENDING"
fi

# Final status check
if [ -f "$PBIN/wmbusmeters" ] && [ -x "$PBIN/wmbusmeters" ]; then
    INSTALLED_VERSION=$("$PBIN/wmbusmeters" --version 2>&1 | head -n1)
    echo "<OK> WMBusMeters ready: $INSTALLED_VERSION"
    echo "<OK> Binary location: $PBIN/wmbusmeters"
    WMBUSMETERS_BIN="$PBIN/wmbusmeters"
elif command -v wmbusmeters &> /dev/null; then
    INSTALLED_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<OK> WMBusMeters ready: $INSTALLED_VERSION"
    echo "<OK> Binary location: $WMBUSMETERS_BIN"
else
    echo "<FAIL> WMBusMeters installation failed"
    echo "<INFO> See log above for details"
    echo "<INFO> Build tools required: g++, make, librtlsdr-dev, rtl-sdr"
    echo "<INFO> Install with: apt-get install -y g++ make librtlsdr-dev rtl-sdr"
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

# Create installation script that will be run with sudo in postinstall
cat > $PBIN/install-wmbusmeters.sh << 'EOFINSTALL'
#!/bin/bash
# WMBusMeters Installation Script
# This script is run with sudo by postinstall.sh

echo "Installing WMBusMeters from Debian repository..."

# Check if already installed
if command -v wmbusmeters &> /dev/null; then
    VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "WMBusMeters already installed: $VERSION"
    exit 0
fi

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    exit 1
fi

# Update and install
export DEBIAN_FRONTEND=noninteractive
echo "Updating package lists..."
apt-get update -qq

echo "Installing wmbusmeters..."
apt-get install -y wmbusmeters

# Verify
if command -v wmbusmeters &> /dev/null; then
    VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "SUCCESS: WMBusMeters installed: $VERSION"
    exit 0
else
    echo "ERROR: Installation failed"
    exit 1
fi
EOFINSTALL

chmod +x $PBIN/install-wmbusmeters.sh

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

# Install sudoers file for installation and service management
echo "<INFO> Installing sudoers configuration..."

# Create sudoers file
cat > /tmp/wmbusmeters_sudoers << SUDOERS_EOF
# Sudoers file for WMBusMeters Plugin
# Installation script
loxberry ALL=(ALL) NOPASSWD: /opt/loxberry/bin/plugins/wmbusmeters/install-wmbusmeters.sh

# Service management
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl start wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl stop wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl restart wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl status wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl enable wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl disable wmbusmeters
loxberry ALL=(ALL) NOPASSWD: /bin/systemctl is-active wmbusmeters
SUDOERS_EOF

# Try to install it - this MIGHT work if we have the right permissions
if cp /tmp/wmbusmeters_sudoers /etc/sudoers.d/loxberry-plugin-wmbusmeters 2>/dev/null; then
    chmod 0440 /etc/sudoers.d/loxberry-plugin-wmbusmeters 2>/dev/null
    chown root:root /etc/sudoers.d/loxberry-plugin-wmbusmeters 2>/dev/null
    echo "<OK> Sudoers configuration installed"
else
    echo "<INFO> Sudoers file will be installed by LoxBerry (needs root)"
    # LoxBerry will install it from the plugin's install directory
fi
rm -f /tmp/wmbusmeters_sudoers

# Clean up
cd /tmp
rm -rf wmbusmeters

echo "<OK> Installation completed successfully"
echo "<INFO> Click 'Install Now' button in web interface to install WMBusMeters"
echo "<INFO> Documentation: https://github.com/wmbusmeters/wmbusmeters"

exit 0
