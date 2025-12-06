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

# Load LoxBerry environment
. $LBHOMEDIR/libs/bashlib/loxberry_system.sh

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

echo "<INFO> Installing dependencies..."

# Update package lists
apt-get update

# Install required packages
apt-get install -y \
    build-essential \
    git \
    cmake \
    pkg-config \
    librtlsdr-dev \
    libusb-1.0-0-dev \
    mosquitto-clients \
    nc

echo "<INFO> Installing wmbusmeters..."

# Check if wmbusmeters is already installed
if command -v wmbusmeters &> /dev/null; then
    echo "<INFO> wmbusmeters is already installed, checking version..."
    CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "<INFO> Current version: $CURRENT_VERSION"
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<INFO> Using existing installation at: $WMBUSMETERS_BIN"
else
    # Try to install from package repository first
    echo "<INFO> Attempting to install wmbusmeters from package repository..."
    
    # Add wmbusmeters repository if not already added
    if [ ! -f /etc/apt/sources.list.d/wmbusmeters.list ]; then
        echo "<INFO> Adding wmbusmeters repository..."
        wget -q -O - https://weetmuts.github.io/wmbusmeters/wmbusmeters-pubkey.gpg | apt-key add - 2>&1 || echo "<WARN> Could not add GPG key"
        echo "deb http://weetmuts.github.io/wmbusmeters buster main" > /etc/apt/sources.list.d/wmbusmeters.list 2>&1 || echo "<WARN> Could not add repository"
        apt-get update 2>&1 || echo "<WARN> apt-get update failed"
    fi
    
    # Try package installation
    if apt-get install -y wmbusmeters 2>&1; then
        echo "<OK> wmbusmeters installed from package"
        WMBUSMETERS_BIN=$(which wmbusmeters)
    else
        echo "<WARN> Package installation failed, trying manual build..."
        
        # Clone and build wmbusmeters
        cd /tmp
        if [ -d "wmbusmeters" ]; then
            rm -rf wmbusmeters
        fi

        echo "<INFO> Cloning wmbusmeters repository..."
        if ! git clone https://github.com/wmbusmeters/wmbusmeters.git; then
            echo "<FAIL> Failed to clone wmbusmeters repository"
            exit 1
        fi
        cd wmbusmeters

        echo "<INFO> Building wmbusmeters..."
        if ! make; then
            echo "<FAIL> Failed to build wmbusmeters"
            exit 1
        fi

        echo "<INFO> Installing wmbusmeters..."
        if ! make install; then
            echo "<FAIL> Failed to install wmbusmeters"
            exit 1
        fi

        # Update library cache
        ldconfig

        # Force rehash PATH
        hash -r
        
        # Clean up
        cd /tmp
        rm -rf wmbusmeters
    fi
fi

# Verify installation - check multiple locations
echo "<INFO> Verifying wmbusmeters installation..."
if [ -z "$WMBUSMETERS_BIN" ]; then
    if [ -f "/usr/local/bin/wmbusmeters" ]; then
        WMBUSMETERS_BIN="/usr/local/bin/wmbusmeters"
    elif [ -f "/usr/bin/wmbusmeters" ]; then
        WMBUSMETERS_BIN="/usr/bin/wmbusmeters"
    elif [ -f "/usr/sbin/wmbusmeters" ]; then
        WMBUSMETERS_BIN="/usr/sbin/wmbusmeters"
    else
        echo "<FAIL> wmbusmeters binary not found after installation"
        echo "<INFO> Searching for wmbusmeters..."
        find / -name wmbusmeters -type f 2>/dev/null | head -10
        exit 1
    fi
fi

echo "<OK> Found wmbusmeters at: $WMBUSMETERS_BIN"

# Test the binary
if ! $WMBUSMETERS_BIN --version &> /dev/null; then
    echo "<FAIL> wmbusmeters binary exists but cannot execute"
    ls -la $WMBUSMETERS_BIN
    file $WMBUSMETERS_BIN
    exit 1
fi

INSTALLED_VERSION=$($WMBUSMETERS_BIN --version 2>&1 | head -n1)
echo "<OK> wmbusmeters installed successfully: $INSTALLED_VERSION"
echo "<OK> Binary location: $WMBUSMETERS_BIN"

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

# Create systemd service file using the detected binary location
CONFPATH="$PCONFIG/wmbusmeters.conf"
echo "<INFO> Creating systemd service with config path: $CONFPATH"
echo "<INFO> Using binary at: $WMBUSMETERS_BIN"
cat > /etc/systemd/system/wmbusmeters.service << EOFSERVICE
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

if [ -f "/etc/systemd/system/wmbusmeters.service" ]; then
    echo "<OK> Systemd service created successfully"
    echo "<INFO> Service file content:"
    cat /etc/systemd/system/wmbusmeters.service
else
    echo "<FAIL> Failed to create systemd service"
    exit 1
fi

# Create log directory for wmbusmeters
mkdir -p /var/log/wmbusmeters
chown loxberry:loxberry /var/log/wmbusmeters
chmod 775 /var/log/wmbusmeters

# Add loxberry user to dialout group for serial port access
usermod -a -G dialout loxberry

# Reload systemd daemon
systemctl daemon-reload

# Enable and start service
echo "<INFO> Enabling wmbusmeters service..."
systemctl enable wmbusmeters

# Don't start service automatically - user needs to configure first
echo "<INFO> Service enabled but not started - please configure first"

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
