<?php
/**
 * Mihomo Gateway API
 * Backend API untuk Web UI
 */

header('Content-Type: application/json');

// Configuration
$MIHOMO_API = 'http://127.0.0.1:9090';
$MIHOMO_SECRET = ''; // Add your secret if configured
$CONFIG_PATH = '/etc/mihomo/config.yaml';
$LOG_PATH = '/var/log/mihomo/mihomo.log';

// Helper function to execute shell commands
function execCommand($command) {
    $output = [];
    $return_var = 0;
    exec("sudo $command 2>&1", $output, $return_var);
    return [
        'success' => $return_var === 0,
        'output' => implode("\n", $output),
        'return_code' => $return_var
    ];
}

// Helper function to call Mihomo API
function callMihomoAPI($endpoint, $method = 'GET', $data = null) {
    global $MIHOMO_API, $MIHOMO_SECRET;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $MIHOMO_API . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    
    if ($MIHOMO_SECRET) {
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $MIHOMO_SECRET
        ]);
    }
    
    if ($method === 'POST' || $method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json'
            ]);
        }
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($response === false || $httpCode !== 200) {
        return null;
    }
    
    return json_decode($response, true);
}

// Get action from request
$action = $_GET['action'] ?? $_POST['action'] ?? '';

// Handle actions
switch ($action) {
    
    // Check Mihomo status
    case 'status':
        $result = execCommand('systemctl is-active mihomo');
        $running = trim($result['output']) === 'active';
        
        echo json_encode([
            'success' => true,
            'running' => $running,
            'status' => $running ? 'running' : 'stopped'
        ]);
        break;
    
    // Control Mihomo service
    case 'control_mihomo':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart'])) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid command'
            ]);
            break;
        }
        
        $result = execCommand("systemctl $command mihomo");
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 
                "Mihomo $command successful" : 
                "Failed to $command Mihomo: " . $result['output']
        ]);
        break;
    
    // Reload configuration
    case 'reload_config':
        $result = execCommand('systemctl reload mihomo');
        
        if (!$result['success']) {
            $result = execCommand('systemctl restart mihomo');
        }
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 
                'Configuration reloaded' : 
                'Failed to reload configuration'
        ]);
        break;
    
    // Get system information
    case 'system_info':
        // Get Mihomo version
        $version = callMihomoAPI('/version');
        
        // Get mode
        $configs = callMihomoAPI('/configs');
        
        // Get system uptime
        $uptime = shell_exec('uptime -p');
        
        // Get CPU usage
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 100 / 4, 1); // Assuming 4 cores
        
        // Get memory usage
        $memInfo = [];
        $memFile = file('/proc/meminfo');
        foreach ($memFile as $line) {
            list($key, $value) = explode(':', $line);
            $memInfo[trim($key)] = (int)trim($value);
        }
        $memTotal = $memInfo['MemTotal'];
        $memFree = $memInfo['MemFree'] + $memInfo['Buffers'] + $memInfo['Cached'];
        $memUsage = round(($memTotal - $memFree) / $memTotal * 100, 1);
        
        echo json_encode([
            'success' => true,
            'data' => [
                'version' => $version['version'] ?? 'Unknown',
                'mode' => $configs['mode'] ?? 'Unknown',
                'uptime' => trim($uptime),
                'cpu' => $cpuUsage,
                'memory' => $memUsage
            ]
        ]);
        break;
    
    // Get traffic data
    case 'traffic':
        $traffic = callMihomoAPI('/traffic');
        
        echo json_encode([
            'success' => $traffic !== null,
            'data' => $traffic
        ]);
        break;
    
    // Get connections
    case 'connections':
        $connections = callMihomoAPI('/connections');
        
        echo json_encode([
            'success' => $connections !== null,
            'data' => $connections
        ]);
        break;
    
    // Close connection
    case 'close_connection':
        $id = $_POST['id'] ?? '';
        
        if (empty($id)) {
            echo json_encode([
                'success' => false,
                'message' => 'Connection ID required'
            ]);
            break;
        }
        
        $result = callMihomoAPI("/connections/$id", 'DELETE');
        
        echo json_encode([
            'success' => $result !== null,
            'message' => 'Connection closed'
        ]);
        break;
    
    // Get proxies
    case 'proxies':
        $proxies = callMihomoAPI('/proxies');
        
        echo json_encode([
            'success' => $proxies !== null,
            'data' => $proxies
        ]);
        break;
    
    // Select proxy
    case 'select_proxy':
        $group = $_POST['group'] ?? '';
        $proxy = $_POST['proxy'] ?? '';
        
        if (empty($group) || empty($proxy)) {
            echo json_encode([
                'success' => false,
                'message' => 'Group and proxy name required'
            ]);
            break;
        }
        
        $result = callMihomoAPI("/proxies/$group", 'PUT', [
            'name' => $proxy
        ]);
        
        echo json_encode([
            'success' => $result !== null,
            'message' => 'Proxy selected'
        ]);
        break;
    
    // Hotspot status
    case 'hotspot_status':
        $hostapdStatus = execCommand('systemctl is-active hostapd');
        $running = trim($hostapdStatus['output']) === 'active';
        
        $ssid = 'N/A';
        $clients = 0;
        
        if ($running) {
            // Get SSID from config
            $hostapdConf = @file_get_contents('/etc/hostapd/hostapd.conf');
            if ($hostapdConf) {
                preg_match('/ssid=(.+)/', $hostapdConf, $matches);
                $ssid = $matches[1] ?? 'N/A';
            }
            
            // Count clients
            if (file_exists('/var/lib/misc/dnsmasq.leases')) {
                $leases = file('/var/lib/misc/dnsmasq.leases');
                $clients = count($leases);
            }
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'running' => $running,
                'ssid' => $ssid,
                'clients' => $clients
            ]
        ]);
        break;
    
    // Control hotspot
    case 'control_hotspot':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart'])) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid command'
            ]);
            break;
        }
        
        // Use smart hotspot script
        $scriptPath = dirname(__DIR__) . '/scripts/hotspot.sh';
        if (file_exists($scriptPath)) {
            $result = execCommand("bash $scriptPath $command");
        } else {
            // Fallback to systemctl
            $result = execCommand("systemctl $command hostapd");
            if ($result['success']) {
                execCommand("systemctl $command dnsmasq");
            }
        }
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 
                "Hotspot $command successful" : 
                "Failed to $command hotspot"
        ]);
        break;
    
    // Configure hotspot
    case 'configure_hotspot':
        $ssid = $_POST['ssid'] ?? '';
        $password = $_POST['password'] ?? '';
        $channel = $_POST['channel'] ?? 'auto';
        
        if (empty($ssid)) {
            echo json_encode([
                'success' => false,
                'message' => 'SSID required'
            ]);
            break;
        }
        
        if (!empty($password) && strlen($password) < 8) {
            echo json_encode([
                'success' => false,
                'message' => 'Password must be at least 8 characters'
            ]);
            break;
        }
        
        // Update hostapd config
        $hostapdConf = '/etc/hostapd/hostapd.conf';
        if (file_exists($hostapdConf)) {
            $config = file_get_contents($hostapdConf);
            
            // Update SSID
            $config = preg_replace('/^ssid=.*/m', "ssid=$ssid", $config);
            
            // Update password if provided
            if (!empty($password)) {
                $config = preg_replace('/^wpa_passphrase=.*/m', "wpa_passphrase=$password", $config);
            }
            
            // Update channel if not auto
            if ($channel !== 'auto' && is_numeric($channel)) {
                $config = preg_replace('/^channel=.*/m', "channel=$channel", $config);
            }
            
            file_put_contents($hostapdConf, $config);
            
            // Restart hostapd if running
            $status = execCommand('systemctl is-active hostapd');
            if (trim($status['output']) === 'active') {
                execCommand('systemctl restart hostapd');
                execCommand('systemctl restart dnsmasq');
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Hotspot configuration updated'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Hostapd config file not found'
            ]);
        }
        break;
    
    // Get hotspot configuration
    case 'get_hotspot_config':
        $hostapdConf = '/etc/hostapd/hostapd.conf';
        if (file_exists($hostapdConf)) {
            $config = file_get_contents($hostapdConf);
            
            // Parse config
            preg_match('/^ssid=(.+)$/m', $config, $ssidMatch);
            preg_match('/^channel=(.+)$/m', $config, $channelMatch);
            preg_match('/^interface=(.+)$/m', $config, $interfaceMatch);
            
            echo json_encode([
                'success' => true,
                'data' => [
                    'ssid' => $ssidMatch[1] ?? 'Unknown',
                    'channel' => $channelMatch[1] ?? 'auto',
                    'interface' => $interfaceMatch[1] ?? 'Unknown'
                ]
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Config file not found'
            ]);
        }
        break;
    
    // Get hotspot clients
    case 'hotspot_clients':
        $clients = 0;
        
        if (file_exists('/var/lib/misc/dnsmasq.leases')) {
            $leases = file('/var/lib/misc/dnsmasq.leases');
            $clients = count($leases);
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'count' => $clients
            ]
        ]);
        break;
    
    // Get network interfaces
    case 'interfaces':
        $output = shell_exec('ip -j addr show');
        $interfaces = json_decode($output, true);
        
        $result = [];
        foreach ($interfaces as $iface) {
            $ip = '';
            if (isset($iface['addr_info']) && count($iface['addr_info']) > 0) {
                foreach ($iface['addr_info'] as $addr) {
                    if ($addr['family'] === 'inet') {
                        $ip = $addr['local'] . '/' . $addr['prefixlen'];
                        break;
                    }
                }
            }
            
            $result[] = [
                'name' => $iface['ifname'],
                'status' => $iface['operstate'],
                'ip' => $ip,
                'mac' => $iface['address'] ?? 'N/A'
            ];
        }
        
        echo json_encode([
            'success' => true,
            'data' => $result
        ]);
        break;
    
    // Get logs
    case 'logs':
        $lines = $_GET['lines'] ?? 100;
        
        if (file_exists($LOG_PATH)) {
            $logs = shell_exec("tail -n $lines $LOG_PATH");
        } else {
            $logs = shell_exec("journalctl -u mihomo -n $lines --no-pager");
        }
        
        echo json_encode([
            'success' => true,
            'data' => $logs
        ]);
        break;
    
    // Get rules
    case 'rules':
        $rules = callMihomoAPI('/rules');
        
        echo json_encode([
            'success' => $rules !== null,
            'data' => $rules
        ]);
        break;
    
    // Get configuration
    case 'get_config':
        if (file_exists($CONFIG_PATH)) {
            $config = file_get_contents($CONFIG_PATH);
            
            echo json_encode([
                'success' => true,
                'data' => $config
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Config file not found'
            ]);
        }
        break;
    
    // Save configuration
    case 'save_config':
        $config = $_POST['config'] ?? '';
        
        if (empty($config)) {
            echo json_encode([
                'success' => false,
                'message' => 'Config data required'
            ]);
            break;
        }
        
        // Backup current config
        $backup = $CONFIG_PATH . '.backup.' . date('YmdHis');
        copy($CONFIG_PATH, $backup);
        
        // Save new config
        $result = file_put_contents($CONFIG_PATH, $config);
        
        if ($result !== false) {
            // Validate config
            $validate = execCommand('/opt/mihomo/mihomo -t -d /etc/mihomo -f ' . $CONFIG_PATH);
            
            if ($validate['success']) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Configuration saved successfully'
                ]);
            } else {
                // Restore backup
                copy($backup, $CONFIG_PATH);
                
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid configuration: ' . $validate['output']
                ]);
            }
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to save configuration'
            ]);
        }
        break;
    
    // Test proxy
    case 'test_proxy':
        $proxy = $_POST['proxy'] ?? '';
        
        if (empty($proxy)) {
            echo json_encode([
                'success' => false,
                'message' => 'Proxy name required'
            ]);
            break;
        }
        
        $result = callMihomoAPI("/proxies/$proxy/delay", 'GET');
        
        echo json_encode([
            'success' => $result !== null,
            'data' => $result
        ]);
        break;
    
    // Get provider status
    case 'providers':
        $providers = callMihomoAPI('/providers/proxies');
        
        echo json_encode([
            'success' => $providers !== null,
            'data' => $providers
        ]);
        break;
    
    // Update provider
    case 'update_provider':
        $provider = $_POST['provider'] ?? '';
        
        if (empty($provider)) {
            echo json_encode([
                'success' => false,
                'message' => 'Provider name required'
            ]);
            break;
        }
        
        $result = callMihomoAPI("/providers/proxies/$provider", 'PUT');
        
        echo json_encode([
            'success' => $result !== null,
            'message' => 'Provider updated'
        ]);
        break;
    
    // Get connected clients
    case 'clients':
        $result = execCommand('bash /opt/mihomo-gateway/scripts/client-monitor.sh json /tmp/clients.json && cat /tmp/clients.json');
        
        if ($result['success']) {
            echo $result['output'];
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to get clients',
                'clients' => []
            ]);
        }
        break;
    
    // Add static IP lease
    case 'add_static_ip':
        $mac = $_POST['mac'] ?? '';
        $ip = $_POST['ip'] ?? '';
        $hostname = $_POST['hostname'] ?? '';
        
        if (empty($mac) || empty($ip)) {
            echo json_encode([
                'success' => false,
                'message' => 'MAC and IP required'
            ]);
            break;
        }
        
        $result = execCommand("bash /opt/mihomo-gateway/scripts/client-monitor.sh add-static $mac $ip $hostname");
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 'Static IP added' : 'Failed to add static IP'
        ]);
        break;
    
    // Run speedtest
    case 'speedtest':
        $mode = $_GET['mode'] ?? 'run';
        
        if ($mode === 'cached') {
            $result = execCommand('bash /opt/mihomo-gateway/scripts/speedtest-api.sh cached');
        } else {
            // Run speedtest in background
            $result = execCommand('bash /opt/mihomo-gateway/scripts/speedtest-api.sh run');
        }
        
        if ($result['success']) {
            echo $result['output'];
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Speedtest failed',
                'error' => $result['output']
            ]);
        }
        break;
    
    // Default - invalid action
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Invalid action'
        ]);
        break;
}
?>
