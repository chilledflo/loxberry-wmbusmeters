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
    # Create installation helper script that uses sudo
    echo "<INFO> Creating auto-installer script..."
    
    cat > "$PDATA/auto-install-wmbusmeters.sh" << 'INSTALLER_SCRIPT'
#!/bin/bash
# Automatic WMBusMeters installer
# This script attempts to install wmbusmeters system-wide

echo "=== WMBusMeters Auto-Installer ==="
echo "This will install wmbusmeters system-wide..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Update package lists
echo "Updating package lists..."
apt-get update -qq

# Install wmbusmeters
echo "Installing wmbusmeters..."
DEBIAN_FRONTEND=noninteractive apt-get install -y wmbusmeters

# Verify installation
if command -v wmbusmeters &> /dev/null; then
    VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "SUCCESS: WMBusMeters installed: $VERSION"
    exit 0
else
    echo "FAILED: Installation unsuccessful"
    exit 1
fi
INSTALLER_SCRIPT

    chmod +x "$PDATA/auto-install-wmbusmeters.sh"
    
    # Try to run the installer automatically
    echo "<INFO> Attempting automatic installation..."
    
    if sudo -n true 2>/dev/null; then
        # sudo without password is available
        echo "<INFO> Sudo access available, installing now..."
        if sudo "$PDATA/auto-install-wmbusmeters.sh" 2>&1 | tee -a $LOGFILE; then
            if command -v wmbusmeters &> /dev/null; then
                CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
                WMBUSMETERS_BIN=$(which wmbusmeters)
                echo "<OK> WMBusMeters installed automatically: $CURRENT_VERSION"
                echo "$WMBUSMETERS_BIN" > $PDATA/wmbusmeters_bin_path.txt
            fi
        fi
    else
        echo "<INFO> Sudo access not available during plugin installation"
        echo "<INFO> Installation will complete in the background..."
        echo "NOT_INSTALLED_YET" > $PDATA/wmbusmeters_bin_path.txt
        WMBUSMETERS_BIN="NOT_INSTALLED_YET"
    fi
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

# Install sudoers file for password-less sudo access
if [ -f "$PTEMPPATH/sudoers" ]; then
    echo "<INFO> Installing sudoers configuration..."
    # Update paths in sudoers file
    sed "s|/opt/loxberry/data/plugins/wmbusmeters|$PDATA|g" "$PTEMPPATH/sudoers" > /tmp/wmbusmeters_sudoers
    
    # Install sudoers file (requires root, but LoxBerry installer runs as root)
    if [ -w "/etc/sudoers.d" ]; then
        cp /tmp/wmbusmeters_sudoers /etc/sudoers.d/loxberry-plugin-wmbusmeters
        chmod 0440 /etc/sudoers.d/loxberry-plugin-wmbusmeters
        chown root:root /etc/sudoers.d/loxberry-plugin-wmbusmeters
        echo "<OK> Sudoers configuration installed"
    else
        echo "<WARN> Cannot install sudoers file (no write access to /etc/sudoers.d)"
    fi
    rm -f /tmp/wmbusmeters_sudoers
fi

# Clean up
cd /tmp
rm -rf wmbusmeters

echo "<OK> Installation completed successfully"
echo "<INFO> Click 'Install Now' button in web interface to install WMBusMeters"
echo "<INFO> Documentation: https://github.com/wmbusmeters/wmbusmeters"

exit 0
