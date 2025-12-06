# LoxBerry WMBusMeters Plugin

Ein LoxBerry-Plugin zur Integration von WMBusMeters für das Auslesen von Funk-Wasserzählern, Wärmezählern, Stromzählern und anderen Smart-Meter-Geräten.

## Beschreibung

Dieses Plugin integriert [WMBusMeters](https://github.com/wmbusmeters/wmbusmeters) in LoxBerry und ermöglicht das Auslesen von Verbrauchsdaten verschiedener Zählertypen über Wireless M-Bus (WMBus).

## Features

- ✅ Automatische Installation von WMBusMeters
- ✅ Web-Interface zur Konfiguration und Überwachung
- ✅ Service-Management (Start/Stop/Restart)
- ✅ Log-Anzeige und Debugging
- ✅ Unterstützung verschiedener WMBus-Empfänger
- ✅ JSON-Ausgabe für einfache Integration
- ✅ MQTT-Unterstützung (optional)
- ✅ Mehrere Zähler gleichzeitig auslesen

## Voraussetzungen

- LoxBerry (empfohlen: Version 2.x oder höher)
- Ein WMBus-Empfänger, z.B.:
  - IMST iM871A USB-Stick
  - Amber Wireless AMB8465-M USB-Stick
  - RTL-SDR USB-Stick (mit rtl_wmbus)
  - Andere kompatible Empfänger

## Installation

1. Laden Sie das Plugin als ZIP-Datei herunter
2. Melden Sie sich in Ihrem LoxBerry an
3. Gehen Sie zu "System" → "Plugin Installation"
4. Wählen Sie die ZIP-Datei aus und installieren Sie das Plugin
5. Warten Sie, bis die Installation abgeschlossen ist

Die Installation umfasst:
- Automatische Installation aller Abhängigkeiten
- Kompilierung von WMBusMeters
- Einrichtung des Systemd-Service
- Erstellung der Verzeichnisstruktur

## Erste Schritte

1. **Hardware anschließen**
   - Schließen Sie Ihren WMBus-Empfänger an einen USB-Port an
   - Überprüfen Sie im Dashboard, ob das Gerät erkannt wurde

2. **Zähler konfigurieren**
   - Öffnen Sie das Plugin im LoxBerry-Webinterface
   - Gehen Sie zur "Konfiguration"
   - Fügen Sie Ihre Zähler hinzu (siehe Beispiele unten)

3. **Service starten**
   - Gehen Sie zum "Dashboard"
   - Klicken Sie auf "Start"
   - Überprüfen Sie die Logs auf empfangene Daten

## Konfiguration

### Basis-Konfiguration

Die Konfigurationsdatei befindet sich unter:
```
/opt/loxberry/data/plugins/wmbusmeters/config/wmbusmeters.conf
```

### Beispiel: Wasserzähler

```conf
# Allgemeine Einstellungen
loglevel=normal
device=auto:t1
format=json
logfile=/var/log/wmbusmeters/wmbusmeters.log

# Wasserzähler
name=Wasserzaehler_Keller
type=multical21
id=12345678
key=00000000000000000000000000000000
```

### Beispiel: Mehrere Zähler

```conf
loglevel=normal
device=/dev/ttyUSB0:im871a:t1
format=json
logfile=/var/log/wmbusmeters/wmbusmeters.log

# Wasserzähler
name=Wasser_Haus
type=multical21
id=12345678
key=00000000000000000000000000000000

# Wärmezähler
name=Heizung_Wohnzimmer
type=multical302
id=87654321
key=11223344556677889900AABBCCDDEEFF

# Stromzähler
name=Strom_Hauptzaehler
type=amiplus
id=11223344
key=00000000000000000000000000000000
```

### Parameter-Erklärung

- **loglevel**: `normal`, `verbose`, `debug`, `silent`
- **device**: 
  - `auto` - Automatische Erkennung
  - `auto:t1` - Automatisch mit T1-Modus
  - `/dev/ttyUSB0:im871a:t1` - Spezifisches Gerät
  - `rtlwmbus` - RTL-SDR Dongle
- **format**: `json`, `fields`, `hr` (human readable)
- **name**: Beliebiger Name für den Zähler
- **type**: Zählertyp (siehe unterstützte Typen)
- **id**: Zähler-ID (meist auf dem Gerät aufgedruckt)
- **key**: Verschlüsselungsschlüssel (falls verwendet)

## Unterstützte Zählertypen

### Wasserzähler
- multical21
- supercom587
- iperl
- hydrus
- izar
- mkradio3
- qcaloric

### Wärmezähler
- multical302
- multical403
- vario451
- compact5
- fhkvdataiii

### Stromzähler
- amiplus
- apator162
- emh
- unismart

### Gaszähler
- bmeters
- apator162
- rfmamb

Vollständige Liste: [WMBusMeters Supported Meters](https://github.com/wmbusmeters/wmbusmeters#supported-meters)

## MQTT-Integration

Um Daten per MQTT zu senden, fügen Sie diese Zeile zur Konfiguration hinzu:

```conf
shell=/usr/bin/mosquitto_pub -h localhost -t wmbusmeters/$METER_NAME -m "$METER_JSON"
```

Oder für einen externen MQTT-Broker:

```conf
shell=/usr/bin/mosquitto_pub -h 192.168.1.100 -u username -P password -t wmbusmeters/$METER_NAME -m "$METER_JSON"
```

## Datenausgabe

Die Zählerdaten werden im JSON-Format ausgegeben:

```json
{
  "media": "water",
  "meter": "multical21",
  "name": "Wasserzaehler_Keller",
  "id": "12345678",
  "total_m3": 123.456,
  "target_m3": 120.000,
  "current_status": "OK",
  "timestamp": "2025-12-06T10:30:00Z"
}
```

## Fehlerbehebung

### Zähler werden nicht erkannt

1. Überprüfen Sie, ob der USB-Stick erkannt wird:
   ```bash
   ls -l /dev/ttyUSB* /dev/ttyACM*
   ```

2. Prüfen Sie die Service-Logs:
   ```bash
   sudo journalctl -u wmbusmeters -f
   ```

3. Testen Sie den Empfang:
   ```bash
   wmbusmeters --listento=t1 auto:t1
   ```

### Service startet nicht

1. Überprüfen Sie die Konfiguration:
   ```bash
   wmbusmeters --useconfig=/opt/loxberry/data/plugins/wmbusmeters/config
   ```

2. Prüfen Sie Berechtigungen:
   ```bash
   sudo usermod -a -G dialout loxberry
   ```

3. Starten Sie den Service neu:
   ```bash
   sudo systemctl restart wmbusmeters
   ```

### Keine Daten empfangen

1. Stellen Sie sicher, dass die Zähler-ID korrekt ist
2. Überprüfen Sie den Verschlüsselungsschlüssel
3. Prüfen Sie die Reichweite zwischen Empfänger und Zähler
4. Aktivieren Sie Telegram-Logging: `logtelegrams=true`

## Verzeichnisstruktur

```
/opt/loxberry/data/plugins/wmbusmeters/
├── config/
│   └── wmbusmeters.conf          # Hauptkonfiguration
├── data/                          # Plugin-Daten
├── bin/
│   └── wmbusmeters-control.sh    # Service-Steuerung
├── log/                           # Plugin-Logs
└── webfrontend/
    └── htmlauth/
        ├── index.php              # Dashboard
        ├── config.php             # Konfiguration
        └── log.php                # Log-Anzeige

/var/log/wmbusmeters/
├── wmbusmeters.log               # Service-Log
└── meter_readings                # Messwerte
```

## Kommandozeilen-Steuerung

```bash
# Service starten
sudo systemctl start wmbusmeters

# Service stoppen
sudo systemctl stop wmbusmeters

# Service-Status prüfen
sudo systemctl status wmbusmeters

# Logs anzeigen
sudo journalctl -u wmbusmeters -f

# Konfiguration testen
wmbusmeters --useconfig=/opt/loxberry/data/plugins/wmbusmeters/config
```

## Updates

Das Plugin unterstützt automatische Updates über das LoxBerry-System. Bei Updates werden:
- Ihre Konfigurationsdateien gesichert
- WMBusMeters auf die neueste Version aktualisiert
- Der Service automatisch neu gestartet

## Deinstallation

Bei der Deinstallation wird:
- Der WMBusMeters-Service gestoppt und deaktiviert
- Die WMBusMeters-Software entfernt
- Die Konfigurationsdateien bleiben als Backup erhalten

Um auch die Konfiguration zu löschen:
```bash
sudo rm -rf /var/log/wmbusmeters
```

## Technische Details

- **Programmiersprache**: Bash (Skripte), PHP (Webinterface), C++ (WMBusMeters)
- **Service-Management**: systemd
- **Web-Framework**: LoxBerry Web Library
- **Datenformat**: JSON
- **Log-Verwaltung**: LoxBerry Log System

## Links

- [WMBusMeters GitHub](https://github.com/wmbusmeters/wmbusmeters)
- [WMBusMeters Wiki](https://github.com/wmbusmeters/wmbusmeters/wiki)
- [LoxBerry Forum](https://www.loxforum.com)
- [LoxBerry Dokumentation](https://www.loxwiki.eu)

## Lizenz

Dieses Plugin steht unter der MIT-Lizenz. WMBusMeters selbst ist GPL-3.0 lizenziert.

## Support

Bei Fragen oder Problemen:
1. Prüfen Sie die Logs im Web-Interface
2. Konsultieren Sie die WMBusMeters-Dokumentation
3. Suchen Sie im LoxBerry-Forum
4. Erstellen Sie ein Issue auf GitHub

## Changelog

### Version 1.0.0 (2025-12-06)
- Erste Veröffentlichung
- WMBusMeters-Integration
- Web-Interface für Konfiguration und Monitoring
- Service-Management
- Unterstützung für verschiedene Zählertypen
- MQTT-Integration (optional)
- Log-Anzeige

## Autor

Name: Your Name  
E-Mail: your.email@example.com

## Danksagungen

Danke an:
- Das WMBusMeters-Projekt für die großartige Software
- Die LoxBerry-Community für Unterstützung und Feedback
