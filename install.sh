#!/bin/bash

# Installation script for WMBusMeters Plugin
# Will be executed during installation and updates

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
LOGFILE=$LOGDIR/install.log
touch $LOGFILE
exec > >(tee -a $LOGFILE) 2>&1

echo "<INFO> Installation script started for $PLUGINNAME"
echo "<INFO> Plugin directory: $PLUGINDIR"

# Create necessary directories
echo "<INFO> Creating plugin directories..."
mkdir -p $PLUGINDIR/config
mkdir -p $PLUGINDIR/data
mkdir -p $PLUGINDIR/bin
mkdir -p $PLUGINDIR/log

# Set permissions
chown -R loxberry:loxberry $PLUGINDIR
chmod -R 775 $PLUGINDIR

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
make
make install

# Create default configuration
echo "<INFO> Creating default configuration..."
cat > $PLUGINDIR/config/wmbusmeters.conf << 'EOF'
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

# Create systemd service file
echo "<INFO> Creating systemd service..."
cat > /etc/systemd/system/wmbusmeters.service << EOF
[Unit]
Description=WMBus Meters Service
After=network.target
Documentation=https://github.com/wmbusmeters/wmbusmeters

[Service]
Type=simple
User=loxberry
Group=loxberry
ExecStart=/usr/bin/wmbusmeters --useconfig=$PLUGINDIR/config
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

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
cat > $PLUGINDIR/bin/wmbusmeters-control.sh << 'EOF'
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
EOF

chmod +x $PLUGINDIR/bin/wmbusmeters-control.sh

# Clean up
cd /tmp
rm -rf wmbusmeters

echo "<OK> Installation completed successfully"
echo "<INFO> Please configure your meters in the web interface"
echo "<INFO> Documentation: https://github.com/wmbusmeters/wmbusmeters"

exit 0
