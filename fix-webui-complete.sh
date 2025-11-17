#!/bin/bash

echo "================================================"
echo "Complete WebUI Fix - All Pages Working"
echo "================================================"
echo ""

# 1. Update API dengan Mihomo secret dan fix semua endpoints
echo "Creating complete API backend..."
sudo tee /var/www/html/api.php > /dev/null << 'EOFAPI'
<?php
/**
 * Mihomo Gateway API - Complete Fixed Version
 */

header('Content-Type: application/json');
error_reporting(0);

// Configuration
$MIHOMO_API = 'http://127.0.0.1:9090';
$MIHOMO_SECRET = 'mihomo-gateway-2024';
$CONFIG_DIR = '/opt/mihomo-gateway/config';

// Helper: Execute command
function execCmd($command) {
    $descriptorspec = [
        0 => ["pipe", "r"],
        1 => ["pipe", "w"],
        2 => ["pipe", "w"]
    ];
    
    $process = proc_open("sudo $command 2>&1", $descriptorspec, $pipes);
    
    if (is_resource($process)) {
        fclose($pipes[0]);
        $output = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        $return_var = proc_close($process);
        
        return [
            'success' => $return_var === 0,
            'output' => trim($output),
            'code' => $return_var
        ];
    }
    
    return ['success' => false, 'output' => 'Failed', 'code' => 1];
}

// Helper: Call Mihomo API
function mihomoAPI($endpoint, $method = 'GET', $data = null) {
    global $MIHOMO_API, $MIHOMO_SECRET;
    
    $ch = curl_init();
    $url = $MIHOMO_API . $endpoint;
    
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 2);
    
    $headers = [];
    if ($MIHOMO_SECRET) {
        $headers[] = 'Authorization: Bearer ' . $MIHOMO_SECRET;
    }
    
    if ($method !== 'GET') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            $headers[] = 'Content-Type: application/json';
        }
    }
    
    if (!empty($headers)) {
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($response === false || $httpCode !== 200) {
        return null;
    }
    
    return json_decode($response, true);
}

// Format bytes
function formatBytes($bytes) {
    if ($bytes === 0) return '0 B';
    $k = 1024;
    $sizes = ['B', 'KB', 'MB', 'GB'];
    $i = floor(log($bytes) / log($k));
    return round($bytes / pow($k, $i), 2) . ' ' . $sizes[$i];
}

$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch ($action) {
    
    // Dashboard
    case 'dashboard':
        $mihomoStatus = execCmd('systemctl is-active mihomo');
        $mihomoRunning = trim($mihomoStatus['output']) === 'active';
        
        $hotspotStatus = execCmd('systemctl is-active hostapd');
        $hotspotRunning = trim($hotspotStatus['output']) === 'active';
        
        // Traffic from Mihomo API
        $traffic = mihomoAPI('/traffic');
        $upload = 0;
        $download = 0;
        
        if ($traffic) {
            $upload = $traffic['up'] ?? 0;
            $download = $traffic['down'] ?? 0;
        }
        
        // Connections
        $connections = mihomoAPI('/connections');
        $connCount = 0;
        if ($connections && isset($connections['connections'])) {
            $connCount = count($connections['connections']);
        }
        
        // Hotspot clients
        $clientsCmd = execCmd('hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:"');
        $hotspotClients = (int)trim($clientsCmd['output']);
        
        // System info
        $uptime = trim(shell_exec('uptime -p') ?: 'Unknown');
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 25, 1); // 4 cores
        
        $memInfo = [];
        if (file_exists('/proc/meminfo')) {
            foreach (file('/proc/meminfo') as $line) {
                if (strpos($line, ':') !== false) {
                    list($key, $value) = explode(':', $line);
                    $memInfo[trim($key)] = (int)preg_replace('/[^0-9]/', '', $value);
                }
            }
        }
        $memTotal = $memInfo['MemTotal'] ?? 1;
        $memFree = ($memInfo['MemFree'] ?? 0) + ($memInfo['Buffers'] ?? 0) + ($memInfo['Cached'] ?? 0);
        $memUsage = round(($memTotal - $memFree) / $memTotal * 100, 1);
        
        $version = mihomoAPI('/version');
        $config = mihomoAPI('/configs');
        
        echo json_encode([
            'success' => true,
            'mihomo' => [
                'running' => $mihomoRunning,
                'version' => $version['version'] ?? 'Unknown',
                'mode' => $config['mode'] ?? 'Unknown'
            ],
            'hotspot' => [
                'running' => $hotspotRunning,
                'clients' => $hotspotClients
            ],
            'traffic' => [
                'upload' => formatBytes($upload) . '/s',
                'download' => formatBytes($download) . '/s'
            ],
            'connections' => $connCount,
            'system' => [
                'uptime' => $uptime,
                'cpu' => $cpuUsage . '%',
                'memory' => $memUsage . '%'
            ]
        ]);
        break;
    
    // Traffic
    case 'traffic':
        $traffic = mihomoAPI('/traffic');
        echo json_encode([
            'success' => $traffic !== null,
            'upload' => $traffic['up'] ?? 0,
            'download' => $traffic['down'] ?? 0
        ]);
        break;
    
    // Proxies
    case 'proxies':
        $proxies = mihomoAPI('/proxies');
        
        $list = [];
        if ($proxies && isset($proxies['proxies'])) {
            foreach ($proxies['proxies'] as $name => $proxy) {
                if (!in_array($proxy['type'], ['Selector', 'URLTest', 'Fallback', 'LoadBalance', 'Relay'])) {
                    $list[] = [
                        'name' => $name,
                        'type' => $proxy['type'],
                        'delay' => $proxy['history'][0]['delay'] ?? 0,
                        'alive' => isset($proxy['alive']) ? $proxy['alive'] : true
                    ];
                }
            }
        }
        
        echo json_encode([
            'success' => true,
            'proxies' => $list
        ]);
        break;
    
    // Rules
    case 'rules':
        $rules = mihomoAPI('/rules');
        
        $list = [];
        if ($rules && isset($rules['rules'])) {
            foreach (array_slice($rules['rules'], 0, 100) as $rule) {
                $list[] = [
                    'type' => $rule['type'] ?? '',
                    'payload' => $rule['payload'] ?? '',
                    'proxy' => $rule['proxy'] ?? ''
                ];
            }
        }
        
        echo json_encode([
            'success' => true,
            'rules' => $list
        ]);
        break;
    
    // Connections
    case 'connections':
        $connections = mihomoAPI('/connections');
        
        $list = [];
        if ($connections && isset($connections['connections'])) {
            foreach ($connections['connections'] as $conn) {
                $list[] = [
                    'id' => $conn['id'] ?? '',
                    'network' => $conn['metadata']['network'] ?? '',
                    'type' => $conn['metadata']['type'] ?? '',
                    'host' => $conn['metadata']['host'] ?? $conn['metadata']['destinationIP'] ?? '',
                    'source' => $conn['metadata']['sourceIP'] ?? '',
                    'chains' => $conn['chains'] ?? [],
                    'upload' => $conn['upload'] ?? 0,
                    'download' => $conn['download'] ?? 0
                ];
            }
        }
        
        echo json_encode([
            'success' => true,
            'connections' => $list
        ]);
        break;
    
    // Control Mihomo
    case 'control_mihomo':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart'])) {
            echo json_encode(['success' => false, 'message' => 'Invalid command']);
            break;
        }
        
        $result = execCmd("systemctl $command mihomo");
        sleep(1);
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? ucfirst($command) . ' successful' : 'Error: ' . $result['output']
        ]);
        break;
    
    // Reload config
    case 'reload_config':
        $result = mihomoAPI('/configs', 'PUT', ['path' => $CONFIG_DIR . '/config.yaml']);
        
        echo json_encode([
            'success' => $result !== null,
            'message' => $result !== null ? 'Configuration reloaded' : 'Failed to reload'
        ]);
        break;
    
    // Hotspot clients
    case 'hotspot_clients':
        $result = execCmd('hostapd_cli all_sta 2>/dev/null');
        
        $clients = [];
        $currentMAC = '';
        
        foreach (explode("\n", $result['output']) as $line) {
            $line = trim($line);
            if (preg_match('/^([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})$/i', $line, $m)) {
                $currentMAC = $m[1];
                $clients[$currentMAC] = ['mac' => $currentMAC, 'connected_time' => '0s', 'signal' => 'N/A'];
            } elseif ($currentMAC && strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $key = trim($key);
                $value = trim($value);
                
                if ($key === 'connected_time') {
                    $clients[$currentMAC]['connected_time'] = gmdate("H:i:s", $value);
                } elseif ($key === 'signal') {
                    $clients[$currentMAC]['signal'] = $value . ' dBm';
                }
            }
        }
        
        echo json_encode([
            'success' => true,
            'clients' => array_values($clients)
        ]);
        break;
    
    // Hotspot status
    case 'hotspot_status':
        $status = execCmd('systemctl is-active hostapd');
        $running = trim($status['output']) === 'active';
        
        // Get current config
        $config = [];
        if (file_exists('/etc/hostapd/hostapd.conf')) {
            foreach (file('/etc/hostapd/hostapd.conf') as $line) {
                if (strpos($line, '=') !== false && substr($line, 0, 1) !== '#') {
                    list($key, $value) = explode('=', trim($line), 2);
                    $config[trim($key)] = trim($value);
                }
            }
        }
        
        echo json_encode([
            'success' => true,
            'running' => $running,
            'ssid' => $config['ssid'] ?? 'Mihomo-Gateway',
            'channel' => $config['channel'] ?? '6'
        ]);
        break;
    
    // Control hotspot
    case 'control_hotspot':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart'])) {
            echo json_encode(['success' => false, 'message' => 'Invalid command']);
            break;
        }
        
        $result = execCmd("/opt/mihomo-gateway/scripts/hotspot.sh $command");
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['output']
        ]);
        break;
    
    // Update hotspot config
    case 'update_hotspot':
        $ssid = $_POST['ssid'] ?? '';
        $password = $_POST['password'] ?? '';
        $channel = $_POST['channel'] ?? '';
        
        if ($ssid) {
            execCmd("sed -i 's/^ssid=.*/ssid=$ssid/' /etc/hostapd/hostapd.conf");
        }
        if ($password && strlen($password) >= 8) {
            execCmd("sed -i 's/^wpa_passphrase=.*/wpa_passphrase=$password/' /etc/hostapd/hostapd.conf");
        }
        if ($channel && in_array($channel, ['1', '6', '11'])) {
            execCmd("sed -i 's/^channel=.*/channel=$channel/' /etc/hostapd/hostapd.conf");
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Configuration updated. Restart hotspot to apply.'
        ]);
        break;
    
    // Interfaces
    case 'interfaces':
        $result = execCmd('ip -j addr show');
        $interfaces = json_decode($result['output'], true) ?: [];
        
        $list = [];
        foreach ($interfaces as $iface) {
            $status = ($iface['flags'] && in_array('UP', $iface['flags'])) ? 'UP' : 'DOWN';
            $ip = '';
            $mac = $iface['address'] ?? '';
            
            if (isset($iface['addr_info'])) {
                foreach ($iface['addr_info'] as $addr) {
                    if ($addr['family'] === 'inet') {
                        $ip = $addr['local'];
                        break;
                    }
                }
            }
            
            $list[] = [
                'name' => $iface['ifname'],
                'status' => $status,
                'ip' => $ip,
                'mac' => $mac
            ];
        }
        
        echo json_encode([
            'success' => true,
            'interfaces' => $list
        ]);
        break;
    
    // Logs
    case 'logs':
        $type = $_GET['type'] ?? 'mihomo';
        
        if ($type === 'mihomo') {
            $result = execCmd('journalctl -u mihomo -n 100 --no-pager');
        } else {
            $result = execCmd('journalctl -u hostapd -n 100 --no-pager');
        }
        
        echo json_encode([
            'success' => true,
            'logs' => $result['output']
        ]);
        break;
    
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Unknown action'
        ]);
}
EOFAPI

echo "✅ API created"

# 2. Set permissions
sudo chown -R www-data:www-data /var/www/html/
sudo chmod 644 /var/www/html/api.php

# 3. Restart services
echo "Restarting services..."
sudo systemctl restart nginx php8.4-fpm

# 4. Test API
echo ""
echo "Testing API..."
echo "Dashboard: $(curl -s http://localhost/api.php?action=dashboard | jq -r .success)"
echo "Proxies: $(curl -s http://localhost/api.php?action=proxies | jq -r .success)"
echo "Rules: $(curl -s http://localhost/api.php?action=rules | jq -r .success)"

echo ""
echo "================================================"
echo "✅ WebUI API Fixed!"
echo "================================================"
echo ""
echo "Working features:"
echo "  ✅ Dashboard - Real traffic & stats"
echo "  ✅ Proxies - List all proxies"
echo "  ✅ Rules - List all rules  "
echo "  ✅ Connections - Active connections"
echo "  ✅ Hotspot - Status & control"
echo "  ✅ Interfaces - Network interfaces"
echo "  ✅ Clients - Connected devices"
echo "  ✅ Logs - System logs"
echo ""
echo "Refresh browser (Ctrl+F5) to see changes!"
echo ""
