<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WMBusMeters Konfiguration</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
        }
        .button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        .button:hover {
            background-color: #0056b3;
        }
        textarea {
            width: 100%;
            min-height: 400px;
            font-family: monospace;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        .info-box {
            background-color: #d1ecf1;
            color: #0c5460;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .success-box {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .error-box {
            background-color: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
    </style>
</head>
<body>

<?php
require_once "loxberry_system.php";
require_once "loxberry_web.php";

// Plugin configuration
$pluginname = "wmbusmeters";
$psubfolder = "";

// LoxBerry Web Interface
$navbar[1]['Name'] = "Dashboard";
$navbar[1]['URL'] = "index.php";

$navbar[2]['Name'] = "Konfiguration";
$navbar[2]['URL'] = "config.php";
$navbar[2]['active'] = true;

$navbar[3]['Name'] = "Log";
$navbar[3]['URL'] = "log.php";

LBWeb::lbheader($pluginname." Plugin", "", "");

// Get plugin directories
$plugindir = $lbpplugindir;
$configfile = "$plugindir/config/wmbusmeters.conf";

// Handle form submission
$message = "";
$message_type = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_config'])) {
    $config_content = $_POST['config_content'];
    
    // Save configuration
    if (file_put_contents($configfile, $config_content) !== false) {
        $message = "Konfiguration erfolgreich gespeichert!";
        $message_type = "success";
        
        // Restart service if running
        exec("systemctl is-active wmbusmeters 2>&1", $status_output, $status_return);
        if ($status_return === 0 && trim($status_output[0]) === 'active') {
            exec("sudo systemctl restart wmbusmeters 2>&1");
            $message .= " Service wurde neugestartet.";
        }
    } else {
        $message = "Fehler beim Speichern der Konfiguration!";
        $message_type = "error";
    }
}

// Read current configuration
$config_content = "";
if (file_exists($configfile)) {
    $config_content = file_get_contents($configfile);
} else {
    $config_content = "# WMBusmeters Konfigurationsdatei nicht gefunden\n";
    $message = "Konfigurationsdatei nicht gefunden. Bitte erstellen Sie eine neue Konfiguration.";
    $message_type = "error";
}

?>

<div class="container">
    <h1>WMBusMeters Konfiguration</h1>
    
    <?php if ($message): ?>
    <div class="<?php echo $message_type; ?>-box">
        <?php echo htmlspecialchars($message); ?>
    </div>
    <?php endif; ?>

    <div class="info-box">
        <h3>Konfigurationshinweise:</h3>
        <p>Bearbeiten Sie die Konfigurationsdatei nach Ihren Bedürfnissen. Grundlegende Parameter:</p>
        <ul>
            <li><strong>device</strong>: Der WMBus-Empfänger (z.B. auto:t1, /dev/ttyUSB0, rtlwmbus)</li>
            <li><strong>loglevel</strong>: normal, verbose, debug, silent</li>
            <li><strong>format</strong>: json, fields, hr (human readable)</li>
        </ul>
        <p>Für jeden Zähler fügen Sie einen Block hinzu:</p>
        <pre>name=MeinZaehler
type=multical21
id=12345678
key=00112233445566778899AABBCCDDEEFF</pre>
        <p>Dokumentation: <a href="https://github.com/wmbusmeters/wmbusmeters/wiki" target="_blank">WMBusMeters Wiki</a></p>
    </div>

    <h2>Konfigurationsdatei bearbeiten</h2>
    <form method="post">
        <textarea name="config_content"><?php echo htmlspecialchars($config_content); ?></textarea>
        <br>
        <button type="submit" name="save_config" class="button">Speichern & Service neustarten</button>
    </form>

    <h2>Beispiel-Konfiguration</h2>
    <div class="info-box">
        <h3>Vollständiges Beispiel:</h3>
        <pre># Allgemeine Einstellungen
loglevel=normal
device=auto:t1
donotprobe=/dev/ttyAMA0
logtelegrams=false
format=json
meterfiles=/var/log/wmbusmeters/meter_readings
meterfilesaction=append
logfile=/var/log/wmbusmeters/wmbusmeters.log

# MQTT (optional)
# shell=/usr/bin/mosquitto_pub -h localhost -t wmbusmeters/$METER_NAME -m "$METER_JSON"

# Wasserzähler Beispiel
name=Wasserzaehler
type=multical21
id=12345678
key=00000000000000000000000000000000

# Wärmezähler Beispiel
name=Waermezaehler
type=multical302
id=87654321
key=00000000000000000000000000000000

# Stromzähler Beispiel
name=Stromzaehler
type=amiplus
id=11223344
key=00000000000000000000000000000000</pre>
    </div>

    <h2>Unterstützte Zählertypen</h2>
    <div class="info-box">
        <p>WMBusMeters unterstützt viele verschiedene Zählertypen, u.a.:</p>
        <ul>
            <li><strong>Wasserzähler:</strong> multical21, supercom587, iperl, hydrus, izar</li>
            <li><strong>Wärmezähler:</strong> multical302, multical403, vario451, compact5</li>
            <li><strong>Stromzähler:</strong> amiplus, apator162, emh</li>
            <li><strong>Gaszähler:</strong> bmeters, apator162</li>
        </ul>
        <p>Eine vollständige Liste finden Sie in der <a href="https://github.com/wmbusmeters/wmbusmeters#supported-meters" target="_blank">WMBusMeters Dokumentation</a></p>
    </div>
</div>

<?php
LBWeb::lbfooter();
?>

</body>
</html>
