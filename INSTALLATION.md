# Installation Instructions / Installationsanleitung

## Deutsch

### Vorbereitung
1. Erstellen Sie ein ZIP-Archiv mit allen Plugin-Dateien
2. Die Verzeichnisstruktur muss korrekt sein (siehe unten)

### Installation
1. Melden Sie sich in Ihrem LoxBerry an (http://your-loxberry-ip)
2. Gehen Sie zu "System" → "Plugin Installation"
3. Klicken Sie auf "Plugin von Datei installieren"
4. Wählen Sie die ZIP-Datei aus
5. Warten Sie, bis die Installation abgeschlossen ist (ca. 5-10 Minuten)

### Nach der Installation
1. Öffnen Sie das WMBusMeters Plugin
2. Schließen Sie Ihren WMBus-Empfänger an
3. Konfigurieren Sie Ihre Zähler unter "Konfiguration"
4. Starten Sie den Service im "Dashboard"

### ZIP-Struktur
```
wmbusmeters-plugin.zip
├── plugin.cfg
├── preinstall.sh
├── preupgrade.sh
├── install.sh
├── uninstall.sh
├── release.cfg
├── README.md
├── INSTALLATION.md
├── wmbusmeters.svg
└── webfrontend/
    └── htmlauth/
        ├── index.php
        ├── config.php
        └── log.php
```

### ZIP erstellen (Linux/Mac)
```bash
cd "Loxberry WMBusMeters"
zip -r ../wmbusmeters-plugin.zip .
```

### ZIP erstellen (Windows PowerShell)
```powershell
Compress-Archive -Path "C:\Loxberry WMBusMeters\*" -DestinationPath "C:\wmbusmeters-plugin.zip"
```

## English

### Preparation
1. Create a ZIP archive with all plugin files
2. The directory structure must be correct (see below)

### Installation
1. Log in to your LoxBerry (http://your-loxberry-ip)
2. Go to "System" → "Plugin Installation"
3. Click "Install plugin from file"
4. Select the ZIP file
5. Wait for installation to complete (approx. 5-10 minutes)

### After Installation
1. Open the WMBusMeters plugin
2. Connect your WMBus receiver
3. Configure your meters under "Configuration"
4. Start the service in the "Dashboard"

### Requirements
- LoxBerry 2.x or higher
- WMBus USB receiver (IMST iM871A, Amber AMB8465-M, RTL-SDR, etc.)
- Internet connection during installation (for downloading dependencies)

### Troubleshooting
If installation fails:
1. Check the installation log in the plugin logs
2. Ensure you have enough disk space (min. 100 MB)
3. Check internet connectivity
4. Try installing manually via SSH (see README.md)

## Support

For issues and questions:
- Check the README.md for detailed documentation
- Visit the LoxBerry forum
- Check WMBusMeters documentation: https://github.com/wmbusmeters/wmbusmeters
