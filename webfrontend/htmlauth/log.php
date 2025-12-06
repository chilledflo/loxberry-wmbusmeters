<?php
require_once "loxberry_system.php";
require_once "loxberry_web.php";

$pluginname = "wmbusmeters";
$navbar[1]['Name'] = "Dashboard";
$navbar[1]['URL'] = "index.php";
$navbar[2]['Name'] = "Konfiguration";
$navbar[2]['URL'] = "config.php";
$navbar[3]['Name'] = "Log";
$navbar[3]['URL'] = "log.php";
$navbar[3]['active'] = true;

LBWeb::lbheader($pluginname, "", "");

$plugindir = $lbpplugindir;
$log_type = isset($_GET['type']) ? $_GET['type'] : 'install';
$lines = isset($_GET['lines']) ? intval($_GET['lines']) : 200;
?>

<style>
.log-box { background-color: #000; color: #0f0; padding: 15px; border-radius: 4px; font-family: monospace; max-height: 600px; overflow-y: auto; margin: 10px 0; white-space: pre-wrap; word-wrap: break-word; }
select { padding: 8px; border-radius: 4px; border: 1px solid #ddd; margin: 5px; }
</style>

<h1>WMBusMeters Logs</h1>

<div>
    <label>Log-Typ:</label>
    <select onchange="location = 'log.php?type=' + this.value + '&lines=<?php echo $lines; ?>'">
        <option value="install" <?php echo $log_type === 'install' ? 'selected' : ''; ?>>Installation Log</option>
        <option value="service" <?php echo $log_type === 'service' ? 'selected' : ''; ?>>Service Log</option>
        <option value="readings" <?php echo $log_type === 'readings' ? 'selected' : ''; ?>>Meter Readings</option>
    </select>
    
    <label>Anzahl Zeilen:</label>
    <select onchange="location = 'log.php?type=<?php echo $log_type; ?>&lines=' + this.value">
        <option value="50" <?php echo $lines === 50 ? 'selected' : ''; ?>>50</option>
        <option value="100" <?php echo $lines === 100 ? 'selected' : ''; ?>>100</option>
        <option value="200" <?php echo $lines === 200 ? 'selected' : ''; ?>>200</option>
        <option value="500" <?php echo $lines === 500 ? 'selected' : ''; ?>>500</option>
    </select>
    
    <a href="log.php?type=<?php echo $log_type; ?>&lines=<?php echo $lines; ?>" class="btn btn-primary">Aktualisieren</a>
</div>

<?php
$log_content = "";
$log_file = "";

switch ($log_type) {
    case 'service':
        $log_file = "/var/log/wmbusmeters/wmbusmeters.log";
        $title = "Service Log";
        break;
    case 'install':
        $log_file = $lbplogdir . "/install.log";
        $title = "Installation Log";
        break;
    case 'readings':
        $log_file = "/var/log/wmbusmeters/meter_readings";
        $title = "Meter Readings";
        break;
    default:
        $log_file = "/var/log/wmbusmeters/wmbusmeters.log";
        $title = "Service Log";
}

echo "<h2>$title</h2>";
echo "<p><small>Log-Datei: <code>$log_file</code></small></p>";

if (file_exists($log_file)) {
    $log_content = shell_exec("tail -n $lines " . escapeshellarg($log_file));
    if (empty($log_content)) {
        $log_content = "Log-Datei ist leer.";
    }
} else {
    $log_content = "Log-Datei nicht gefunden: $log_file\n\n";
    $log_content .= "Debug-Information:\n";
    $log_content .= "LBPLOGDIR: $lbplogdir\n";
    $log_content .= "LBPPLUGINDIR: $lbpplugindir\n";
    $log_content .= "Current User: " . shell_exec("whoami") . "\n";
    $log_content .= "\nSuche nach alternativen Pfaden...\n";
    
    // Try alternative paths
    $alt_paths = [
        "/opt/loxberry/log/plugins/wmbusmeters/install.log",
        "/opt/loxberry/log/plugins/wmbusmeters/",
        "/opt/loxberry/log/system_tmpfs/",
        "/opt/loxberry/log/",
    ];
    
    foreach ($alt_paths as $alt_path) {
        if (file_exists($alt_path)) {
            if (is_dir($alt_path)) {
                $log_content .= "\nVerzeichnis gefunden: $alt_path\n";
                $log_content .= "Inhalt:\n";
                $log_content .= shell_exec("ls -lah " . escapeshellarg($alt_path) . " 2>&1");
            } else {
                $log_content .= "\nGefunden: $alt_path\n\n";
                $log_content .= shell_exec("tail -n $lines " . escapeshellarg($alt_path));
                break;
            }
        } else {
            $log_content .= "Nicht gefunden: $alt_path\n";
        }
    }
    
    // Check system logs for plugin installation
    $log_content .= "\n\n=== LoxBerry System Logs (Plugin Installation) ===\n";
    $system_log = shell_exec("grep -r 'wmbusmeters' /opt/loxberry/log/system_tmpfs/ 2>&1 | tail -50");
    if (!empty($system_log)) {
        $log_content .= $system_log;
    } else {
        $log_content .= "Keine System-Logs gefunden.\n";
    }
}

echo "<div class='log-box'>";
echo htmlspecialchars($log_content);
echo "</div>";
?>

<h2>Systemd Journal (letzte 50 Einträge)</h2>
<?php
$journal = shell_exec("journalctl -u wmbusmeters -n 50 --no-pager 2>&1");
if (!empty($journal)) {
    echo "<div class='log-box'>";
    echo htmlspecialchars($journal);
    echo "</div>";
} else {
    echo "<div class='log-box'>Keine Journal-Einträge gefunden.</div>";
}
?>

<?php
LBWeb::lbfooter();
?>
