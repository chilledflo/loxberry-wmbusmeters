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
    CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1 | awk '{print $2}')
    echo "<INFO> Current version: $CURRENT_VERSION"
fi

# Clone and build wmbusmeters
cd /tmp
if [ -d "wmbusmeters" ]; then
    rm -rf wmbusmeters
fi

echo "<INFO> Cloning wmbusmeters repository..."
git clone https://github.com/wmbusmeters/wmbusmeters.git
cd wmbusmeters

echo "<INFO> Building wmbusmeters..."
./configure
make

echo "<INFO> Installing wmbusmeters..."
make install

# Update library cache
ldconfig

# Force rehash PATH
hash -r

# Verify installation - check multiple locations
echo "<INFO> Verifying wmbusmeters installation..."
if [ -f "/usr/local/bin/wmbusmeters" ]; then
    echo "<OK> Found wmbusmeters at: /usr/local/bin/wmbusmeters"
    WMBUSMETERS_BIN="/usr/local/bin/wmbusmeters"
elif [ -f "/usr/bin/wmbusmeters" ]; then
    echo "<OK> Found wmbusmeters at: /usr/bin/wmbusmeters"
    WMBUSMETERS_BIN="/usr/bin/wmbusmeters"
else
    echo "<FAIL> wmbusmeters binary not found after installation"
    echo "<INFO> Searching for wmbusmeters..."
    find /usr -name wmbusmeters 2>/dev/null
    exit 1
fi

# Test the binary
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
