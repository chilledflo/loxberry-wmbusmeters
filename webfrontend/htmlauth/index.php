<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WMBusMeters Plugin</title>
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
        .button.stop {
            background-color: #dc3545;
        }
        .button.stop:hover {
            background-color: #c82333;
        }
        .button.restart {
            background-color: #ffc107;
        }
        .button.restart:hover {
            background-color: #e0a800;
        }
        .status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .status.running {
            background-color: #d4edda;
            color: #155724;
        }
        .status.stopped {
            background-color: #f8d7da;
            color: #721c24;
        }
        textarea {
            width: 100%;
            min-height: 300px;
            font-family: monospace;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .log-box {
            background-color: #000;
            color: #0f0;
            padding: 15px;
            border-radius: 4px;
            font-family: monospace;
            max-height: 400px;
            overflow-y: auto;
            margin: 10px 0;
        }
        .info-box {
            background-color: #d1ecf1;
            color: #0c5460;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .warning-box {
            background-color: #fff3cd;
            color: #856404;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 10px 0;
        }
        table th, table td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        table th {
            background-color: #f8f9fa;
            font-weight: bold;
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
$navbar[1]['active'] = true;

$navbar[2]['Name'] = "Konfiguration";
$navbar[2]['URL'] = "config.php";

$navbar[3]['Name'] = "Log";
$navbar[3]['URL'] = "log.php";

LBWeb::lbheader($pluginname." Plugin", "", "");

// Get plugin directories
$plugindir = $lbpplugindir;
$configfile = "$plugindir/config/wmbusmeters.conf";

// Handle form submissions
$message = "";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'start':
                exec("sudo systemctl start wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich gestartet" : "Fehler beim Starten: " . implode("\n", $output);
                break;
            case 'stop':
                exec("sudo systemctl stop wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich gestoppt" : "Fehler beim Stoppen: " . implode("\n", $output);
                break;
            case 'restart':
                exec("sudo systemctl restart wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich neugestartet" : "Fehler beim Neustarten: " . implode("\n", $output);
                break;
        }
    }
}

// Get service status
exec("systemctl is-active wmbusmeters 2>&1", $status_output, $status_return);
$is_running = ($status_return === 0 && trim($status_output[0]) === 'active');

// Get version
exec("wmbusmeters --version 2>&1", $version_output);
$version = isset($version_output[0]) ? trim($version_output[0]) : "Nicht installiert";

?>

<div class="container">
    <h1>WMBusMeters Dashboard</h1>
    
    <?php if ($message): ?>
    <div class="info-box">
        <?php echo htmlspecialchars($message); ?>
    </div>
    <?php endif; ?>

    <h2>Service Status</h2>
    <div class="status <?php echo $is_running ? 'running' : 'stopped'; ?>">
        <strong>Status:</strong> <?php echo $is_running ? '● Läuft' : '○ Gestoppt'; ?>
    </div>

    <form method="post" style="margin: 10px 0;">
        <button type="submit" name="action" value="start" class="button" <?php echo $is_running ? 'disabled' : ''; ?>>
            Start
        </button>
        <button type="submit" name="action" value="stop" class="button stop" <?php echo !$is_running ? 'disabled' : ''; ?>>
            Stop
        </button>
        <button type="submit" name="action" value="restart" class="button restart">
            Neustart
        </button>
    </form>

    <h2>System Information</h2>
    <table>
        <tr>
            <th>Parameter</th>
            <th>Wert</th>
        </tr>
        <tr>
            <td>WMBusMeters Version</td>
            <td><?php echo htmlspecialchars($version); ?></td>
        </tr>
        <tr>
            <td>Plugin Verzeichnis</td>
            <td><?php echo htmlspecialchars($plugindir); ?></td>
        </tr>
        <tr>
            <td>Konfigurationsdatei</td>
            <td><?php echo htmlspecialchars($configfile); ?></td>
        </tr>
    </table>

    <h2>Erkannte Geräte</h2>
    <?php
    // List USB devices
    exec("ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null", $devices_output);
    if (count($devices_output) > 0) {
        echo "<div class='info-box'>";
        echo "<pre>" . htmlspecialchars(implode("\n", $devices_output)) . "</pre>";
        echo "</div>";
    } else {
        echo "<div class='warning-box'>Keine USB/Serial Geräte gefunden</div>";
    }
    ?>

    <h2>Letzte Log-Einträge</h2>
    <?php
    $logfile = "/var/log/wmbusmeters/wmbusmeters.log";
    if (file_exists($logfile)) {
        $log_content = shell_exec("tail -n 20 $logfile");
        echo "<div class='log-box'>";
        echo htmlspecialchars($log_content);
        echo "</div>";
    } else {
        echo "<div class='warning-box'>Log-Datei nicht gefunden</div>";
    }
    ?>

    <h2>Quick Start</h2>
    <div class="info-box">
        <h3>Erste Schritte:</h3>
        <ol>
            <li>Schließen Sie Ihren WMBus-Empfänger an (z.B. IMST iM871A USB-Stick)</li>
            <li>Gehen Sie zur Konfigurationsseite und fügen Sie Ihre Zähler hinzu</li>
            <li>Starten Sie den Service</li>
            <li>Überprüfen Sie die Logs auf empfangene Daten</li>
        </ol>
        <h3>Unterstützte Geräte:</h3>
        <ul>
            <li>IMST iM871A USB-Stick</li>
            <li>Amber Wireless AMB8465-M USB-Stick</li>
            <li>RTL-SDR USB-Stick</li>
            <li>Weitere kompatible WMBus-Empfänger</li>
        </ul>
    </div>

    <h2>Dokumentation</h2>
    <div class="info-box">
        <p>Weitere Informationen und Dokumentation finden Sie auf:</p>
        <ul>
            <li><a href="https://github.com/wmbusmeters/wmbusmeters" target="_blank">WMBusMeters GitHub</a></li>
            <li><a href="https://github.com/wmbusmeters/wmbusmeters/wiki" target="_blank">WMBusMeters Wiki</a></li>
        </ul>
    </div>
</div>

<?php
LBWeb::lbfooter();
?>

</body>
</html>
