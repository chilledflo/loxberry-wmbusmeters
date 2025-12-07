<?php
require_once "loxberry_system.php";
require_once "loxberry_web.php";

$pluginname = "wmbusmeters";
$navbar[1]['Name'] = "Dashboard";
$navbar[1]['URL'] = "index.php";
$navbar[1]['active'] = true;
$navbar[2]['Name'] = "Konfiguration";
$navbar[2]['URL'] = "config.php";
$navbar[3]['Name'] = "Log";
$navbar[3]['URL'] = "log.php";

LBWeb::lbheader($pluginname, "", "");

// Get LoxBerry system paths
$plugindata = LBSystem::plugindata();
$configfile = $lbpconfigdir . "/wmbusmeters.conf";

// Debug: Log the config path
error_log("WMBusMeters: Looking for config at: " . $configfile);

// Handle form submissions
$message = "";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'start':
                exec("sudo systemctl start wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich gestartet" : "Fehler beim Starten";
                break;
            case 'stop':
                exec("sudo systemctl stop wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich gestoppt" : "Fehler beim Stoppen";
                break;
            case 'restart':
                exec("sudo systemctl restart wmbusmeters 2>&1", $output, $return);
                $message = ($return === 0) ? "Service erfolgreich neugestartet" : "Fehler beim Neustarten";
                break;
        }
    }
}

// Get service status
exec("systemctl is-active wmbusmeters 2>&1", $status_output, $status_return);
$is_running = ($status_return === 0 && trim($status_output[0]) === 'active');

// Check if WMBusMeters is installed
$version = "Nicht installiert";
$wmbusmeters_installed = false;
$wmbusmeters_bin = "";

// Check plugin bin directory first
$plugin_bin = $lbpbindir . "/wmbusmeters";
if (file_exists($plugin_bin)) {
    exec($plugin_bin . " --version 2>&1", $version_output, $version_return);
    if ($version_return === 0 && isset($version_output[0])) {
        $version = trim($version_output[0]);
        $wmbusmeters_installed = true;
        $wmbusmeters_bin = $plugin_bin;
    }
}

// Check system locations if not in plugin dir
if (!$wmbusmeters_installed) {
    if (file_exists("/usr/local/bin/wmbusmeters")) {
        exec("/usr/local/bin/wmbusmeters --version 2>&1", $version_output, $version_return);
        if ($version_return === 0 && isset($version_output[0])) {
            $version = trim($version_output[0]);
            $wmbusmeters_installed = true;
            $wmbusmeters_bin = "/usr/local/bin/wmbusmeters";
        }
    } elseif (file_exists("/usr/bin/wmbusmeters")) {
        exec("/usr/bin/wmbusmeters --version 2>&1", $version_output, $version_return);
        if ($version_return === 0 && isset($version_output[0])) {
            $version = trim($version_output[0]);
            $wmbusmeters_installed = true;
            $wmbusmeters_bin = "/usr/bin/wmbusmeters";
        }
    }
}
?>

<style>
.status-box { padding: 15px; margin: 10px 0; border-radius: 4px; }
.status-running { background-color: #d4edda; color: #155724; }
.status-stopped { background-color: #f8d7da; color: #721c24; }
.info-box { background-color: #d1ecf1; color: #0c5460; padding: 15px; border-radius: 4px; margin: 10px 0; }
.warning-box { background-color: #fff3cd; color: #856404; padding: 15px; border-radius: 4px; margin: 10px 0; }
.log-box { background-color: #000; color: #0f0; padding: 15px; border-radius: 4px; font-family: monospace; max-height: 400px; overflow-y: auto; margin: 10px 0; }
table { width: 100%; border-collapse: collapse; margin: 10px 0; }
table th, table td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
table th { background-color: #f8f9fa; font-weight: bold; }
</style>

<h1>WMBusMeters Dashboard</h1>

<?php if (!$wmbusmeters_installed): ?>
<div class="warning-box">
    <h3>⚠️ Installation fehlgeschlagen</h3>
    <p><strong>WMBusMeters wurde während der Plugin-Installation nicht gefunden.</strong></p>
    <p>Dies kann passieren wenn:</p>
    <ul>
        <li>Keine Internetverbindung während der Installation bestand</li>
        <li>Das Debian-Repository nicht erreichbar war</li>
        <li>Ein Installationsfehler aufgetreten ist</li>
    </ul>
    
    <div style="background: #d1ecf1; color: #0c5460; padding: 15px; border-radius: 4px; margin: 20px 0;">
        <h4>🔧 Lösung: Manuelle Installation</h4>
        <p>Führen Sie folgende Befehle als root aus:</p>
        <div style="background: #000; color: #0f0; padding: 10px; border-radius: 4px; font-family: monospace; margin: 10px 0;">
            ssh root@loxberry<br>
            apt-get update<br>
            apt-get install -y wmbusmeters
        </div>
        <p>Danach installieren Sie das Plugin erneut oder laden Sie diese Seite neu.</p>
    </div>
    
    <p><small>Überprüfen Sie das Installations-Log unter System → Log-Dateien → Plugin-Installation für weitere Details.</small></p>
</div>
<?php endif; ?>

<?php if ($message): ?>
<div class="info-box"><?php echo htmlspecialchars($message); ?></div>
<?php endif; ?>

<h2>Service Status</h2>
<?php if ($wmbusmeters_installed): ?>
<div class="status-box <?php echo $is_running ? 'status-running' : 'status-stopped'; ?>">
    <strong>Status:</strong> <?php echo $is_running ? '● Läuft' : '○ Gestoppt'; ?>
</div>

<form method="post">
    <button type="submit" name="action" value="start" class="btn btn-success" <?php echo $is_running ? 'disabled' : ''; ?>>
        Start
    </button>
    <button type="submit" name="action" value="stop" class="btn btn-danger" <?php echo !$is_running ? 'disabled' : ''; ?>>
        Stop
    </button>
    <button type="submit" name="action" value="restart" class="btn btn-warning">
        Neustart
    </button>
</form>
<?php else: ?>
<div class="status-box status-stopped">
    <strong>Status:</strong> ○ Nicht installiert
</div>
<?php endif; ?>

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
        <td>Binary Pfad</td>
        <td><?php echo $wmbusmeters_installed ? htmlspecialchars($wmbusmeters_bin) : '<span style="color: red;">Nicht installiert</span>'; ?></td>
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
exec("ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null", $devices_output);
if (count($devices_output) > 0) {
    echo "<div class='info-box'><pre>" . htmlspecialchars(implode("\n", $devices_output)) . "</pre></div>";
} else {
    echo "<div class='warning-box'>Keine USB/Serial Geräte gefunden</div>";
}
?>

<h2>Letzte Log-Einträge</h2>
<?php
$logfile = "/var/log/wmbusmeters/wmbusmeters.log";
if (file_exists($logfile)) {
    $log_content = shell_exec("tail -n 20 $logfile");
    echo "<div class='log-box'>" . htmlspecialchars($log_content) . "</div>";
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
    </ul>
</div>

<h2>Dokumentation</h2>
<div class="info-box">
    <p>Weitere Informationen:</p>
    <ul>
        <li><a href="https://github.com/wmbusmeters/wmbusmeters" target="_blank">WMBusMeters GitHub</a></li>
        <li><a href="https://github.com/wmbusmeters/wmbusmeters/wiki" target="_blank">WMBusMeters Wiki</a></li>
    </ul>
</div>

<?php
LBWeb::lbfooter();
?>
