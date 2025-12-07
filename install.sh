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
    # GitHub releases contain no pre-built binaries - we must compile from source
    echo "<INFO> Compiling WMBusMeters from source (GitHub has no pre-built binaries)..."
    
    # Check if required system tools are available
    MISSING_TOOLS=""
    for tool in g++ make wget unzip; do
        if ! command -v $tool &> /dev/null; then
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done
    
    if [ -n "$MISSING_TOOLS" ]; then
        echo "<FAIL> Required build tools not available:$MISSING_TOOLS"
        echo "<FAIL> Cannot compile without: g++, make, wget, unzip"
        echo "<FAIL> These must be installed system-wide (requires sudo/root access)"
        echo "<INFO> Manual installation required:"
        echo "<INFO> 1. SSH to LoxBerry as root"
        echo "<INFO> 2. Run: apt-get update && apt-get install -y g++ make librtlsdr-dev rtl-sdr"
        echo "<INFO> 3. Reinstall this plugin"
        echo "NOT_INSTALLED" > $PDATA/wmbusmeters_bin_path.txt
        WMBUSMETERS_BIN="NOT_INSTALLED"
    else
        # Download and compile wmbusmeters
        echo "<INFO> Build tools available, proceeding with compilation..."
        cd /tmp
        
        # Get latest release tag from GitHub API
        echo "<INFO> Fetching latest release version from GitHub..."
        LATEST_VERSION=$(wget -qO- "https://api.github.com/repos/wmbusmeters/wmbusmeters/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        
        if [ -z "$LATEST_VERSION" ]; then
            echo "<WARN> Could not fetch latest version from GitHub API, using fallback version"
            LATEST_VERSION="1.19.0"
        else
            echo "<INFO> Latest version: $LATEST_VERSION"
        fi
        
        COMPILE_SUCCESS=false
        
        echo "<INFO> Compiling version $LATEST_VERSION..."
        
        # Clean up previous attempt
        rm -rf wmbusmeters-* wmbusmeters.zip
        
        # Download source
            if wget -q "https://github.com/wmbusmeters/wmbusmeters/archive/refs/tags/$LATEST_VERSION.zip" -O wmbusmeters.zip; then
            echo "<INFO> Downloaded source code $LATEST_VERSION"
            
            if unzip -q wmbusmeters.zip; then
                # Find the extracted directory (could be wmbusmeters-1.19.0 or wmbusmeters-v1.19.0)
                EXTRACT_DIR=$(ls -d wmbusmeters-* 2>/dev/null | head -n1)
                
                if [ -n "$EXTRACT_DIR" ] && [ -d "$EXTRACT_DIR" ]; then
                    cd "$EXTRACT_DIR"
                    echo "<INFO> Entered directory: $EXTRACT_DIR"
                    
                    # Compile (make only the binary, skip tests)
                    echo "<INFO> Compiling wmbusmeters (this may take 2-3 minutes)..."
                    if make wmbusmeters 2>&1 | tee -a $LOGFILE; then
                        if [ -f "wmbusmeters" ] && [ -x "wmbusmeters" ]; then
                            # Test if it works
                            if ./wmbusmeters --version &> /dev/null; then
                                # Copy to plugin bin directory
                                cp wmbusmeters "$PBIN/wmbusmeters"
                                chmod +x "$PBIN/wmbusmeters"
                                
                                INSTALLED_VERSION=$("$PBIN/wmbusmeters" --version 2>&1 | head -n1)
                                echo "<OK> WMBusMeters compiled successfully: $INSTALLED_VERSION"
                                echo "$PBIN/wmbusmeters" > $PDATA/wmbusmeters_bin_path.txt
                                WMBUSMETERS_BIN="$PBIN/wmbusmeters"
                                COMPILE_SUCCESS=true
                            else
                                echo "<WARN> Binary compiled but doesn't work"
                            fi
                        else
                            echo "<WARN> Compilation produced no working binary"
                        fi
                    else
                        echo "<FAIL> Compilation failed"
                    fi
                    
                    cd /tmp
                else
                    echo "<FAIL> Could not find extracted directory"
                fi
            else
                echo "<FAIL> Could not extract downloaded archive"
            fi
        else
            echo "<FAIL> Could not download source code"
        fi        # Clean up
        cd /tmp
        rm -rf wmbusmeters-* wmbusmeters.zip
        
        if [ "$COMPILE_SUCCESS" = false ]; then
            echo "<FAIL> Compilation of version $LATEST_VERSION failed"
            echo "<INFO> Check installation log for compilation errors"
            echo "<INFO> Verify build tools are installed: g++ make librtlsdr-dev rtl-sdr"
            echo "<INFO> Manual installation may be required"
            echo "NOT_INSTALLED" > $PDATA/wmbusmeters_bin_path.txt
            WMBUSMETERS_BIN="NOT_INSTALLED"
        fi
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

# Clean up
cd /tmp
rm -rf wmbusmeters

echo "<OK> Installation completed successfully"
echo "<INFO> Please configure your meters in the web interface"
echo "<INFO> Documentation: https://github.com/wmbusmeters/wmbusmeters"

exit 0
