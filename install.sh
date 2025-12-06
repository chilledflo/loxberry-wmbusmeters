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
    # Download and install pre-built binary
    echo "<INFO> Downloading pre-built WMBusMeters binary..."
    
    # Determine architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        DOWNLOAD_URL="https://github.com/wmbusmeters/wmbusmeters/releases/latest/download/wmbusmeters_amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "armv7l" ]; then
        DOWNLOAD_URL="https://github.com/wmbusmeters/wmbusmeters/releases/latest/download/wmbusmeters_arm"
    else
        echo "<WARN> Unknown architecture: $ARCH"
        echo "<INFO> Trying generic x86_64 binary..."
        DOWNLOAD_URL="https://github.com/wmbusmeters/wmbusmeters/releases/latest/download/wmbusmeters_amd64"
    fi
    
    echo "<INFO> Architecture: $ARCH"
    echo "<INFO> Download URL: $DOWNLOAD_URL"
    
    # Download static binary from GitHub releases
    echo "<INFO> Downloading static binary from GitHub releases..."
    cd /tmp
    
    # Get latest release info and download static binary
    BINARY_URLS=(
        "https://github.com/wmbusmeters/wmbusmeters/releases/download/1.19.0/wmbusmeters"
        "https://github.com/wmbusmeters/wmbusmeters/releases/download/1.18.0/wmbusmeters"
        "https://github.com/weetmuts/wmbusmeters/releases/download/1.17.1/wmbusmeters"
    )
    
    DOWNLOAD_SUCCESS=false
    for BINARY_URL in "${BINARY_URLS[@]}"; do
        echo "<INFO> Trying: $BINARY_URL"
        if wget -v "$BINARY_URL" -O "$PBIN/wmbusmeters" 2>&1 | tee -a $LOGFILE; then
            if [ -f "$PBIN/wmbusmeters" ] && [ -s "$PBIN/wmbusmeters" ]; then
                chmod +x "$PBIN/wmbusmeters"
                
                # Test if it works
                if "$PBIN/wmbusmeters" --version &> /dev/null; then
                    VERSION=$("$PBIN/wmbusmeters" --version 2>&1 | head -n1)
                    echo "<OK> WMBusMeters installed: $VERSION"
                    echo "$PBIN/wmbusmeters" > $PDATA/wmbusmeters_bin_path.txt
                    DOWNLOAD_SUCCESS=true
                    break
                else
                    echo "<WARN> Binary downloaded but not functional, checking dependencies..."
                    ldd "$PBIN/wmbusmeters" 2>&1 | tee -a $LOGFILE || true
                    file "$PBIN/wmbusmeters" 2>&1 | tee -a $LOGFILE
                    # Try next URL
                    rm -f "$PBIN/wmbusmeters"
                fi
            fi
        fi
        rm -f "$PBIN/wmbusmeters"
    done
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "<FAIL> Could not download working binary from any source"
        echo "<INFO> Tried multiple URLs:"
        for url in "${BINARY_URLS[@]}"; do
            echo "<INFO>   - $url"
        done
        echo "<INFO> Check internet connection and GitHub availability"
        echo "NOT_INSTALLED" > $PDATA/wmbusmeters_bin_path.txt
    fi
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
