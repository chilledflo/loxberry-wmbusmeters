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
$log_type = isset($_GET['type']) ? $_GET['type'] : 'service';
$lines = isset($_GET['lines']) ? intval($_GET['lines']) : 100;
?>

<style>
.log-box { background-color: #000; color: #0f0; padding: 15px; border-radius: 4px; font-family: monospace; max-height: 600px; overflow-y: auto; margin: 10px 0; white-space: pre-wrap; word-wrap: break-word; }
select { padding: 8px; border-radius: 4px; border: 1px solid #ddd; margin: 5px; }
</style>

<h1>WMBusMeters Logs</h1>

<div>
    <label>Log-Typ:</label>
    <select onchange="location = 'log.php?type=' + this.value + '&lines=<?php echo $lines; ?>'">
        <option value="service" <?php echo $log_type === 'service' ? 'selected' : ''; ?>>Service Log</option>
        <option value="install" <?php echo $log_type === 'install' ? 'selected' : ''; ?>>Installation Log</option>
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
        $log_file = "$plugindir/../../../log/plugins/$pluginname/install.log";
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

if (file_exists($log_file)) {
    $log_content = shell_exec("tail -n $lines " . escapeshellarg($log_file));
    if (empty($log_content)) {
        $log_content = "Log-Datei ist leer.";
    }
} else {
    $log_content = "Log-Datei nicht gefunden: $log_file";
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
