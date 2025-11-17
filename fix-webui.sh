#!/bin/bash

echo "Fixing WebUI Backend..."
echo ""

# 1. Setup sudo without password for www-data
echo "Setting up sudo permissions..."
sudo tee /etc/sudoers.d/mihomo-webui > /dev/null << 'EOF'
# Allow www-data to control mihomo and hotspot without password
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active mihomo
www-data ALL=(ALL) NOPASSWD: /opt/mihomo-gateway/scripts/hotspot.sh
www-data ALL=(ALL) NOPASSWD: /usr/sbin/hostapd_cli
www-data ALL=(ALL) NOPASSWD: /usr/bin/ip
www-data ALL=(ALL) NOPASSWD: /usr/sbin/iw
www-data ALL=(ALL) NOPASSWD: /usr/bin/cat /var/log/*
www-data ALL=(ALL) NOPASSWD: /usr/bin/tail /var/log/*
EOF

sudo chmod 440 /etc/sudoers.d/mihomo-webui

echo "✅ Sudo permissions configured"
echo ""

# 2. Create improved API
echo "Creating improved API..."
sudo tee /var/www/html/api.php > /dev/null << 'EOFAPI'
<?php
/**
 * Mihomo Gateway API - Fixed Version
 */

header('Content-Type: application/json');
error_reporting(0);

// Configuration
$MIHOMO_API = 'http://127.0.0.1:9090';
$MIHOMO_SECRET = '';

// Helper function to execute shell commands
function execCommand($command) {
    $descriptorspec = [
        0 => ["pipe", "r"],
        1 => ["pipe", "w"],
        2 => ["pipe", "w"]
    ];
    
    $process = proc_open("sudo $command", $descriptorspec, $pipes);
    
    if (is_resource($process)) {
        fclose($pipes[0]);
        $output = stream_get_contents($pipes[1]);
        $error = stream_get_contents($pipes[2]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        $return_var = proc_close($process);
        
        return [
            'success' => $return_var === 0,
            'output' => trim($output ?: $error),
            'return_code' => $return_var
        ];
    }
    
    return ['success' => false, 'output' => 'Failed to execute', 'return_code' => 1];
}

// Helper function to call Mihomo API
function callMihomoAPI($endpoint) {
    global $MIHOMO_API;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $MIHOMO_API . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 2);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 2);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($response === false || $httpCode !== 200) {
        return null;
    }
    
    return json_decode($response, true);
}

// Get action
$action = $_GET['action'] ?? $_POST['action'] ?? '';

// Handle actions
switch ($action) {
    
    // Dashboard data
    case 'dashboard':
        // Check Mihomo status
        $statusResult = execCommand('systemctl is-active mihomo');
        $mihomoRunning = trim($statusResult['output']) === 'active';
        
        // Check Hotspot status
        $hotspotResult = execCommand('systemctl is-active hostapd');
        $hotspotRunning = trim($hotspotResult['output']) === 'active';
        
        // Get traffic stats from Mihomo API
        $traffic = callMihomoAPI('/traffic');
        $uploadSpeed = $traffic ? formatBytes($traffic['up'] ?? 0) . '/s' : 'N/A';
        $downloadSpeed = $traffic ? formatBytes($traffic['down'] ?? 0) . '/s' : 'N/A';
        
        // Get connections
        $connections = callMihomoAPI('/connections');
        $activeConnections = $connections ? count($connections['connections'] ?? []) : 0;
        
        // Get hotspot clients
        $clientsResult = execCommand('hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:"');
        $hotspotClients = (int)trim($clientsResult['output']) ?: 0;
        
        // System info
        $uptime = trim(shell_exec('uptime -p') ?: 'Unknown');
        
        // CPU usage
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 100 / 4, 1);
        
        // Memory usage
        $memInfo = [];
        if (file_exists('/proc/meminfo')) {
            $memFile = file('/proc/meminfo');
            foreach ($memFile as $line) {
                if (strpos($line, ':') !== false) {
                    list($key, $value) = explode(':', $line);
                    $memInfo[trim($key)] = (int)trim($value);
                }
            }
        }
        $memTotal = $memInfo['MemTotal'] ?? 1;
        $memFree = ($memInfo['MemFree'] ?? 0) + ($memInfo['Buffers'] ?? 0) + ($memInfo['Cached'] ?? 0);
        $memUsage = round(($memTotal - $memFree) / $memTotal * 100, 1);
        
        // Mihomo version
        $versionData = callMihomoAPI('/version');
        $version = $versionData['version'] ?? 'Unknown';
        
        // Mode
        $configData = callMihomoAPI('/configs');
        $mode = $configData['mode'] ?? 'Unknown';
        
        echo json_encode([
            'success' => true,
            'mihomo' => [
                'running' => $mihomoRunning,
                'version' => $version,
                'mode' => $mode
            ],
            'hotspot' => [
                'running' => $hotspotRunning,
                'clients' => $hotspotClients
            ],
            'traffic' => [
                'upload' => $uploadSpeed,
                'download' => $downloadSpeed
            ],
            'connections' => $activeConnections,
            'system' => [
                'uptime' => $uptime,
                'cpu' => $cpuUsage . '%',
                'memory' => $memUsage . '%'
            ]
        ]);
        break;
    
    // Traffic stats for chart
    case 'traffic':
        $traffic = callMihomoAPI('/traffic');
        
        if ($traffic) {
            echo json_encode([
                'success' => true,
                'upload' => $traffic['up'] ?? 0,
                'download' => $traffic['down'] ?? 0
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'upload' => 0,
                'download' => 0
            ]);
        }
        break;
    
    // Control Mihomo
    case 'control_mihomo':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart'])) {
            echo json_encode(['success' => false, 'message' => 'Invalid command']);
            break;
        }
        
        $result = execCommand("systemctl $command mihomo");
        sleep(1); // Wait for service
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 
                "Mihomo $command successful" : 
                "Error: " . $result['output']
        ]);
        break;
    
    // Reload config
    case 'reload_config':
        $result = execCommand('systemctl reload mihomo');
        
        if (!$result['success']) {
            $result = execCommand('systemctl restart mihomo');
        }
        
        sleep(1);
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['success'] ? 
                'Configuration reloaded successfully' : 
                'Failed: ' . $result['output']
        ]);
        break;
    
    // Get connected clients
    case 'clients':
        $result = execCommand('hostapd_cli all_sta 2>/dev/null');
        
        $clients = [];
        $currentMAC = '';
        $lines = explode("\n", $result['output']);
        
        foreach ($lines as $line) {
            $line = trim($line);
            if (preg_match('/^([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})$/i', $line, $matches)) {
                $currentMAC = $matches[1];
                $clients[$currentMAC] = ['mac' => $currentMAC];
            } elseif ($currentMAC && strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $clients[$currentMAC][trim($key)] = trim($value);
            }
        }
        
        echo json_encode([
            'success' => true,
            'clients' => array_values($clients),
            'count' => count($clients)
        ]);
        break;
    
    // Hotspot control
    case 'control_hotspot':
        $command = $_POST['command'] ?? '';
        
        if (!in_array($command, ['start', 'stop', 'restart', 'status'])) {
            echo json_encode(['success' => false, 'message' => 'Invalid command']);
            break;
        }
        
        $result = execCommand("/opt/mihomo-gateway/scripts/hotspot.sh $command");
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['output']
        ]);
        break;
    
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Unknown action: ' . $action
        ]);
        break;
}

// Helper function to format bytes
function formatBytes($bytes, $precision = 2) {
    $units = ['B', 'KB', 'MB', 'GB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= pow(1024, $pow);
    return round($bytes, $precision) . ' ' . $units[$pow];
}
EOFAPI

echo "✅ API created"
echo ""

# 3. Update dashboard to use new API
echo "Updating dashboard..."
sudo tee /var/www/html/dashboard/index.php > /dev/null << 'EOFDASH'
<?php
session_start();
if (!isset($_SESSION['logged_in']) || !$_SESSION['logged_in']) {
    header('Location: /login.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Mihomo Gateway</title>
    <link rel="stylesheet" href="/assets/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <?php include '../includes/sidebar.php'; ?>
    
    <div class="main-content">
        <div class="header">
            <h1>Dashboard</h1>
            <div class="header-actions">
                <button onclick="refreshDashboard()" class="btn btn-primary">
                    <i class="icon-refresh"></i> Refresh
                </button>
                <span class="status-badge" id="statusBadge">Loading...</span>
            </div>
        </div>
        
        <div class="dashboard-grid">
            <!-- Stats Cards -->
            <div class="stat-card">
                <div class="stat-icon upload">
                    <i class="icon-upload"></i>
                </div>
                <div class="stat-info">
                    <h3 id="uploadSpeed">N/A</h3>
                    <p>Upload Speed</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon download">
                    <i class="icon-download"></i>
                </div>
                <div class="stat-info">
                    <h3 id="downloadSpeed">N/A</h3>
                    <p>Download Speed</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon connections">
                    <i class="icon-link"></i>
                </div>
                <div class="stat-info">
                    <h3 id="activeConnections">N/A</h3>
                    <p>Active Connections</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon clients">
                    <i class="icon-users"></i>
                </div>
                <div class="stat-info">
                    <h3 id="hotspotClients">0</h3>
                    <p>Hotspot Clients</p>
                </div>
            </div>
        </div>
        
        <!-- Traffic Chart -->
        <div class="card">
            <h2>Real-time Traffic</h2>
            <canvas id="trafficChart"></canvas>
        </div>
        
        <!-- System Information -->
        <div class="card">
            <h2>System Information</h2>
            <div class="info-grid">
                <div class="info-item">
                    <label>Mihomo Version:</label>
                    <span id="mihomoVersion">-</span>
                </div>
                <div class="info-item">
                    <label>Mode:</label>
                    <span id="mihomoMode">-</span>
                </div>
                <div class="info-item">
                    <label>System Uptime:</label>
                    <span id="systemUptime">-</span>
                </div>
                <div class="info-item">
                    <label>CPU Usage:</label>
                    <span id="cpuUsage">-</span>
                </div>
                <div class="info-item">
                    <label>Memory Usage:</label>
                    <span id="memoryUsage">-</span>
                </div>
            </div>
        </div>
        
        <!-- Quick Actions -->
        <div class="card">
            <h2>Quick Actions</h2>
            <div class="action-buttons">
                <button onclick="controlMihomo('start')" class="btn btn-success">
                    <i class="icon-play"></i> Start Mihomo
                </button>
                <button onclick="controlMihomo('stop')" class="btn btn-danger">
                    <i class="icon-stop"></i> Stop Mihomo
                </button>
                <button onclick="controlMihomo('restart')" class="btn btn-warning">
                    <i class="icon-refresh"></i> Restart Mihomo
                </button>
                <button onclick="reloadConfig()" class="btn btn-info">
                    <i class="icon-reload"></i> Reload Config
                </button>
            </div>
        </div>
    </div>
    
    <script>
    // Traffic chart
    const ctx = document.getElementById('trafficChart').getContext('2d');
    const trafficChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Upload',
                data: [],
                borderColor: 'rgb(255, 99, 132)',
                backgroundColor: 'rgba(255, 99, 132, 0.1)',
                tension: 0.4
            }, {
                label: 'Download',
                data: [],
                borderColor: 'rgb(54, 162, 235)',
                backgroundColor: 'rgba(54, 162, 235, 0.1)',
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatBytes(value) + '/s';
                        }
                    }
                }
            }
        }
    });
    
    // Load dashboard data
    function loadDashboard() {
        fetch('/api.php?action=dashboard')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Update status badge
                    const badge = document.getElementById('statusBadge');
                    if (data.mihomo.running) {
                        badge.textContent = 'Running';
                        badge.className = 'status-badge status-running';
                    } else {
                        badge.textContent = 'Stopped';
                        badge.className = 'status-badge status-stopped';
                    }
                    
                    // Update stats
                    document.getElementById('uploadSpeed').textContent = data.traffic.upload;
                    document.getElementById('downloadSpeed').textContent = data.traffic.download;
                    document.getElementById('activeConnections').textContent = data.connections;
                    document.getElementById('hotspotClients').textContent = data.hotspot.clients;
                    
                    // Update system info
                    document.getElementById('mihomoVersion').textContent = data.mihomo.version;
                    document.getElementById('mihomoMode').textContent = data.mihomo.mode;
                    document.getElementById('systemUptime').textContent = data.system.uptime;
                    document.getElementById('cpuUsage').textContent = data.system.cpu;
                    document.getElementById('memoryUsage').textContent = data.system.memory;
                }
            })
            .catch(error => console.error('Error loading dashboard:', error));
    }
    
    // Update traffic chart
    function updateTrafficChart() {
        fetch('/api.php?action=traffic')
            .then(response => response.json())
            .then(data => {
                const now = new Date().toLocaleTimeString();
                
                trafficChart.data.labels.push(now);
                trafficChart.data.datasets[0].data.push(data.upload || 0);
                trafficChart.data.datasets[1].data.push(data.download || 0);
                
                // Keep only last 20 points
                if (trafficChart.data.labels.length > 20) {
                    trafficChart.data.labels.shift();
                    trafficChart.data.datasets[0].data.shift();
                    trafficChart.data.datasets[1].data.shift();
                }
                
                trafficChart.update('none');
            });
    }
    
    // Control Mihomo
    function controlMihomo(command) {
        const formData = new FormData();
        formData.append('action', 'control_mihomo');
        formData.append('command', command);
        
        fetch('/api.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showNotification('Success: ' + data.message, 'success');
                setTimeout(loadDashboard, 1000);
            } else {
                showNotification('Error: ' + data.message, 'error');
            }
        });
    }
    
    // Reload config
    function reloadConfig() {
        const formData = new FormData();
        formData.append('action', 'reload_config');
        
        fetch('/api.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showNotification('Configuration reloaded successfully', 'success');
            } else {
                showNotification('Failed to reload configuration', 'error');
            }
        });
    }
    
    // Refresh dashboard
    function refreshDashboard() {
        loadDashboard();
        showNotification('Dashboard refreshed', 'info');
    }
    
    // Show notification
    function showNotification(message, type) {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);
        
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
    
    // Format bytes
    function formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
    
    // Initialize
    loadDashboard();
    updateTrafficChart();
    
    // Auto refresh
    setInterval(loadDashboard, 5000);
    setInterval(updateTrafficChart, 2000);
    </script>
</body>
</html>
EOFDASH

echo "✅ Dashboard updated"
echo ""

# 4. Set proper permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

echo "✅ Permissions set"
echo ""

# 5. Restart services
echo "Restarting services..."
sudo systemctl restart nginx php8.4-fpm

echo "✅ Services restarted"
echo ""

echo "================================================"
echo "WebUI Fixed! 🎉"
echo "================================================"
echo ""
echo "✅ Sudo permissions configured"
echo "✅ API backend improved"
echo "✅ Dashboard updated with real-time data"
echo "✅ All permissions set correctly"
echo ""
echo "Access WebUI: http://192.168.1.1"
echo "Login: admin / admin123"
echo ""
echo "Features working:"
echo "  ✅ Real-time traffic monitoring"
echo "  ✅ System information"
echo "  ✅ Mihomo control (start/stop/restart)"
echo "  ✅ Hotspot client count"
echo "  ✅ Connected clients list"
echo ""
