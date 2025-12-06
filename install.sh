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
echo "<INFO> Running apt-get update..."
sudo apt-get update 2>&1 | tee -a $LOGFILE

# Install required packages
echo "<INFO> Installing build dependencies..."
sudo apt-get install -y \
    build-essential \
    git \
    cmake \
    pkg-config \
    librtlsdr-dev \
    libusb-1.0-0-dev \
    mosquitto-clients \
    nc \
    wget \
    curl 2>&1 | tee -a $LOGFILE

if [ $? -ne 0 ]; then
    echo "<WARN> Some dependencies might have failed to install"
fi

echo "<INFO> Installing wmbusmeters..."

# Check if wmbusmeters is already installed
if command -v wmbusmeters &> /dev/null; then
    echo "<INFO> wmbusmeters is already installed, checking version..."
    CURRENT_VERSION=$(wmbusmeters --version 2>&1 | head -n1)
    echo "<INFO> Current version: $CURRENT_VERSION"
    WMBUSMETERS_BIN=$(which wmbusmeters)
    echo "<INFO> Using existing installation at: $WMBUSMETERS_BIN"
else
    # Manual build is more reliable on Raspberry Pi
    echo "<INFO> Building wmbusmeters from source..."
    
    # Clone and build wmbusmeters
    cd /tmp
    if [ -d "wmbusmeters" ]; then
        echo "<INFO> Removing old build directory..."
        rm -rf wmbusmeters
    fi

    echo "<INFO> Cloning wmbusmeters repository..."
    if ! git clone https://github.com/wmbusmeters/wmbusmeters.git 2>&1 | tee -a $LOGFILE; then
        echo "<FAIL> Failed to clone wmbusmeters repository"
        echo "<INFO> Check internet connection and GitHub access"
        exit 1
    fi
    
    cd wmbusmeters
    echo "<INFO> Current directory: $(pwd)"
    echo "<INFO> Build files present:"
    ls -la

    echo "<INFO> Building wmbusmeters (this may take several minutes)..."
    if ! make 2>&1 | tee -a $LOGFILE; then
        echo "<FAIL> Failed to build wmbusmeters"
        echo "<INFO> Check build log above for errors"
        exit 1
    fi
    
    echo "<INFO> Build completed, installing..."
    if ! sudo make install 2>&1 | tee -a $LOGFILE; then
        echo "<FAIL> Failed to install wmbusmeters"
        exit 1
    fi

    # Update library cache
    echo "<INFO> Updating library cache..."
    sudo ldconfig 2>&1 | tee -a $LOGFILE

    # Force rehash PATH
    hash -r
    
    # Clean up
    cd /tmp
    rm -rf wmbusmeters
    echo "<INFO> Cleaned up build directory"
fi

# Verify installation - check multiple locations
echo "<INFO> Verifying wmbusmeters installation..."
echo "<INFO> Checking PATH: $PATH"

# Wait a moment for filesystem sync
sleep 1

if [ -z "$WMBUSMETERS_BIN" ]; then
    # Try which first
    WMBUSMETERS_BIN=$(which wmbusmeters 2>/dev/null)
    
    # If which fails, try common locations
    if [ -z "$WMBUSMETERS_BIN" ] || [ ! -f "$WMBUSMETERS_BIN" ]; then
        echo "<INFO> which command failed, checking common locations..."
        if [ -f "/usr/local/bin/wmbusmeters" ]; then
            WMBUSMETERS_BIN="/usr/local/bin/wmbusmeters"
        elif [ -f "/usr/bin/wmbusmeters" ]; then
            WMBUSMETERS_BIN="/usr/bin/wmbusmeters"
        elif [ -f "/usr/sbin/wmbusmeters" ]; then
            WMBUSMETERS_BIN="/usr/sbin/wmbusmeters"
        else
            echo "<FAIL> wmbusmeters binary not found in common locations"
            echo "<INFO> Searching entire system (this may take a moment)..."
            SEARCH_RESULT=$(find /usr -name wmbusmeters -type f 2>/dev/null | head -1)
            if [ -n "$SEARCH_RESULT" ]; then
                echo "<INFO> Found at: $SEARCH_RESULT"
                WMBUSMETERS_BIN="$SEARCH_RESULT"
            else
                echo "<FAIL> wmbusmeters not found anywhere"
                echo "<INFO> Files in /usr/local/bin:"
                ls -la /usr/local/bin/ 2>/dev/null | grep -i wmbus || echo "No wmbus files found"
                exit 1
            fi
        fi
    fi
fi

echo "<OK> Found wmbusmeters at: $WMBUSMETERS_BIN"
ls -la "$WMBUSMETERS_BIN"

# Test the binary
echo "<INFO> Testing wmbusmeters binary..."
if ! "$WMBUSMETERS_BIN" --version &> /dev/null; then
    echo "<FAIL> wmbusmeters binary exists but cannot execute"
    echo "<INFO> File information:"
    file "$WMBUSMETERS_BIN"
    echo "<INFO> Permissions:"
    ls -la "$WMBUSMETERS_BIN"
    exit 1
fi

INSTALLED_VERSION=$("$WMBUSMETERS_BIN" --version 2>&1 | head -n1)
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
sudo tee /etc/systemd/system/wmbusmeters.service > /dev/null << EOFSERVICE
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
sudo mkdir -p /var/log/wmbusmeters
sudo chown loxberry:loxberry /var/log/wmbusmeters
sudo chmod 775 /var/log/wmbusmeters

# Add loxberry user to dialout group for serial port access
sudo usermod -a -G dialout loxberry

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start service
echo "<INFO> Enabling wmbusmeters service..."
sudo systemctl enable wmbusmeters

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
