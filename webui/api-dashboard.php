<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Mihomo API Configuration
define('MIHOMO_API', 'http://127.0.0.1:9090');
define('MIHOMO_SECRET', 'mihomo-gateway-2024');

// Function to call Mihomo API
function mihomoAPI($endpoint) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, MIHOMO_API . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . MIHOMO_SECRET
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode == 200 && $response) {
        return json_decode($response, true);
    }
    return null;
}

// Function to execute system commands
function execCmd($cmd) {
    $output = [];
    $return = 0;
    exec("sudo $cmd 2>&1", $output, $return);
    return [
        'success' => $return === 0,
        'output' => implode("\n", $output),
        'code' => $return
    ];
}

// Function to format bytes
function formatBytes($bytes) {
    if ($bytes >= 1073741824) {
        return number_format($bytes / 1073741824, 2) . ' GB';
    } elseif ($bytes >= 1048576) {
        return number_format($bytes / 1048576, 2) . ' MB';
    } elseif ($bytes >= 1024) {
        return number_format($bytes / 1024, 2) . ' KB';
    }
    return $bytes . ' B';
}

// Get action
$action = $_GET['action'] ?? 'dashboard';

switch ($action) {
    case 'dashboard':
        // Get all dashboard data
        $version = mihomoAPI('/version');
        $traffic = mihomoAPI('/traffic');
        $connections = mihomoAPI('/connections');
        $proxies = mihomoAPI('/proxies');
        
        // Get system info
        $uptime = trim(shell_exec('uptime -p 2>/dev/null') ?: 'Unknown');
        $cpuUsage = trim(shell_exec("top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1") ?: '0');
        $memInfo = trim(shell_exec("free -m 2>/dev/null | awk 'NR==2{printf \"%.1f\", \$3*100/\$2 }'") ?: '0');
        $diskUsage = trim(shell_exec("df -h / 2>/dev/null | awk 'NR==2{print \$5}' | sed 's/%//'") ?: '0');
        
        // Get Mihomo service status (with sudo)
        $mihomoStatus = execCmd('systemctl is-active mihomo');
        
        // Get hotspot status (with sudo)
        $hotspotStatus = execCmd('systemctl is-active hostapd');
        
        // Get connected clients (count MAC addresses from hostapd_cli)
        $clients = [];
        $clientsOutput = trim(shell_exec('sudo hostapd_cli all_sta 2>/dev/null') ?: '');
        $clientsCount = 0;
        if ($clientsOutput) {
            // Count lines with MAC addresses (format: xx:xx:xx:xx:xx:xx)
            preg_match_all('/^([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})$/im', $clientsOutput, $matches);
            $clients = $matches[1] ?? [];
            $clientsCount = count($clients);
        }
        
        // Get traffic stats (need to stream, so just get current)
        $trafficData = mihomoAPI('/traffic');
        
        $response = [
            'status' => 'success',
            'mihomo' => [
                'version' => $version['version'] ?? 'Unknown',
                'status' => trim($mihomoStatus['output']) === 'active' ? 'Running' : 'Stopped',
                'mode' => $proxies['mode'] ?? 'rule'
            ],
            'traffic' => [
                'upload' => $trafficData['up'] ?? 0,
                'download' => $trafficData['down'] ?? 0,
                'uploadFormatted' => formatBytes($trafficData['up'] ?? 0),
                'downloadFormatted' => formatBytes($trafficData['down'] ?? 0)
            ],
            'connections' => [
                'total' => count($connections['connections'] ?? []),
                'list' => array_slice($connections['connections'] ?? [], 0, 10) // Top 10
            ],
            'hotspot' => [
                'status' => trim($hotspotStatus['output']) === 'active' ? 'Running' : 'Stopped',
                'clients' => $clientsCount,
                'clientList' => $clients,
                'ssid' => 'Mihomo-Gateway'
            ],
            'system' => [
                'uptime' => $uptime ?: 'Unknown',
                'cpu' => round(floatval($cpuUsage), 1) . '%',
                'memory' => round(floatval($memInfo), 1) . '%',
                'disk' => intval($diskUsage) . '%'
            ],
            'timestamp' => time()
        ];
        
        echo json_encode($response, JSON_PRETTY_PRINT);
        break;
        
    case 'traffic':
        // Get real-time traffic (streaming endpoint)
        header('Content-Type: text/event-stream');
        header('Cache-Control: no-cache');
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, MIHOMO_API . '/traffic');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . MIHOMO_SECRET
        ]);
        curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($ch, $data) {
            echo "data: " . $data . "\n\n";
            ob_flush();
            flush();
            return strlen($data);
        });
        
        curl_exec($ch);
        curl_close($ch);
        break;
        
    case 'control':
        // Control Mihomo service (start/stop/restart)
        $command = $_POST['command'] ?? '';
        
        switch ($command) {
            case 'start':
                $result = execCmd('systemctl start mihomo');
                break;
            case 'stop':
                $result = execCmd('systemctl stop mihomo');
                break;
            case 'restart':
                $result = execCmd('systemctl restart mihomo');
                break;
            default:
                $result = ['success' => false, 'output' => 'Invalid command', 'code' => 1];
        }
        
        echo json_encode([
            'status' => $result['success'] ? 'success' : 'error',
            'message' => $result['output'],
            'code' => $result['code']
        ], JSON_PRETTY_PRINT);
        break;
        
    case 'reload':
        // Reload Mihomo configuration
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, MIHOMO_API . '/configs');
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . MIHOMO_SECRET,
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
            'path' => '/opt/mihomo-gateway/config/config.yaml'
        ]));
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo json_encode([
            'status' => $httpCode == 204 ? 'success' : 'error',
            'message' => $httpCode == 204 ? 'Configuration reloaded' : 'Failed to reload',
            'code' => $httpCode
        ], JSON_PRETTY_PRINT);
        break;
        
    case 'proxies':
        // Get all proxies
        $proxies = mihomoAPI('/proxies');
        echo json_encode($proxies ?? ['error' => 'Failed to get proxies'], JSON_PRETTY_PRINT);
        break;
        
    case 'rules':
        // Get all rules
        $rules = mihomoAPI('/rules');
        echo json_encode($rules ?? ['error' => 'Failed to get rules'], JSON_PRETTY_PRINT);
        break;
        
    case 'connections':
        // Get all connections
        $connections = mihomoAPI('/connections');
        echo json_encode($connections ?? ['error' => 'Failed to get connections'], JSON_PRETTY_PRINT);
        break;
        
    default:
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid action'
        ], JSON_PRETTY_PRINT);
}
?>
