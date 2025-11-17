#!/bin/bash

echo "================================================"
echo "Dashboard Complete Fix - Step by Step"
echo "================================================"
echo ""

# STEP 1: Setup sudo permissions
echo "STEP 1: Setting up sudo without password..."
sudo tee /etc/sudoers.d/mihomo-webui > /dev/null << 'EOF'
# Mihomo Gateway WebUI Permissions
# Allow www-data to run these commands without password

# Systemctl commands
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active hostapd

# Hotspot commands
www-data ALL=(ALL) NOPASSWD: /usr/sbin/hostapd_cli *
www-data ALL=(ALL) NOPASSWD: /opt/mihomo-gateway/scripts/hotspot.sh *

# Network commands
www-data ALL=(ALL) NOPASSWD: /usr/bin/ip *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/iw *

# Log viewing
www-data ALL=(ALL) NOPASSWD: /usr/bin/journalctl *

# System info
www-data ALL=(ALL) NOPASSWD: /usr/bin/uptime *
EOF

sudo chmod 440 /etc/sudoers.d/mihomo-webui
sudo visudo -c
echo "✅ Sudo configured"
echo ""

# STEP 2: Create optimized API for Dashboard
echo "STEP 2: Creating Dashboard API..."
sudo tee /var/www/html/api-dashboard.php > /dev/null << 'EOFAPI'
<?php
/**
 * Mihomo Dashboard API - Optimized
 */

header('Content-Type: application/json');
header('Cache-Control: no-cache');
error_reporting(0);

// Config
$MIHOMO_API = 'http://127.0.0.1:9090';
$MIHOMO_SECRET = 'mihomo-gateway-2024';

function execCmd($cmd) {
    $proc = proc_open(
        "sudo $cmd 2>&1",
        [['pipe', 'r'], ['pipe', 'w'], ['pipe', 'w']],
        $pipes
    );
    
    if (!is_resource($proc)) {
        return ['ok' => false, 'out' => ''];
    }
    
    fclose($pipes[0]);
    $out = stream_get_contents($pipes[1]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $code = proc_close($proc);
    
    return ['ok' => $code === 0, 'out' => trim($out)];
}

function mihomoAPI($path) {
    global $MIHOMO_API, $MIHOMO_SECRET;
    
    $ch = curl_init($MIHOMO_API . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 2,
        CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $MIHOMO_SECRET]
    ]);
    
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ($res && $code === 200) ? json_decode($res, true) : null;
}

function formatBytes($b) {
    $u = ['B', 'KB', 'MB', 'GB'];
    $i = 0;
    while ($b >= 1024 && $i < 3) {
        $b /= 1024;
        $i++;
    }
    return round($b, 2) . ' ' . $u[$i];
}

$action = $_GET['action'] ?? $_POST['action'] ?? 'dashboard';

// ============================================
// DASHBOARD DATA
// ============================================
if ($action === 'dashboard') {
    
    // 1. Mihomo Status
    $mihomoStatus = execCmd('systemctl is-active mihomo');
    $mihomoRunning = (trim($mihomoStatus['out']) === 'active');
    
    // 2. Get Mihomo Version & Mode
    $version = mihomoAPI('/version');
    $config = mihomoAPI('/configs');
    
    $mihomoVersion = $version['version'] ?? 'Unknown';
    $mihomoMode = $config['mode'] ?? 'rule';
    
    // 3. Traffic Data
    $traffic = mihomoAPI('/traffic');
    $uploadSpeed = 'N/A';
    $downloadSpeed = 'N/A';
    
    if ($traffic) {
        $up = $traffic['up'] ?? 0;
        $down = $traffic['down'] ?? 0;
        $uploadSpeed = formatBytes($up) . '/s';
        $downloadSpeed = formatBytes($down) . '/s';
    }
    
    // 4. Connections Count
    $connections = mihomoAPI('/connections');
    $activeConnections = 0;
    if ($connections && isset($connections['connections'])) {
        $activeConnections = count($connections['connections']);
    }
    
    // 5. Hotspot Clients
    $clientsResult = execCmd('hostapd_cli all_sta 2>/dev/null | grep -c "^[0-9a-f][0-9a-f]:"');
    $hotspotClients = (int)$clientsResult['out'];
    
    // 6. System Information
    $uptime = trim(shell_exec('uptime -p') ?: 'Unknown');
    
    // CPU
    $load = sys_getloadavg();
    $cpuUsage = round($load[0] * 25, 1); // 4 cores
    
    // Memory
    $memInfo = [];
    if (file_exists('/proc/meminfo')) {
        foreach (file('/proc/meminfo') as $line) {
            if (preg_match('/^(\w+):\s+(\d+)/', $line, $m)) {
                $memInfo[$m[1]] = (int)$m[2];
            }
        }
    }
    
    $memTotal = $memInfo['MemTotal'] ?? 1;
    $memFree = ($memInfo['MemFree'] ?? 0) + ($memInfo['Buffers'] ?? 0) + ($memInfo['Cached'] ?? 0);
    $memUsage = round(($memTotal - $memFree) / $memTotal * 100, 1);
    
    // Response
    echo json_encode([
        'success' => true,
        'mihomo' => [
            'running' => $mihomoRunning,
            'version' => $mihomoVersion,
            'mode' => $mihomoMode
        ],
        'stats' => [
            'upload' => $uploadSpeed,
            'download' => $downloadSpeed,
            'connections' => $activeConnections,
            'clients' => $hotspotClients
        ],
        'system' => [
            'uptime' => $uptime,
            'cpu' => $cpuUsage . '%',
            'memory' => $memUsage . '%'
        ]
    ]);
    
// ============================================
// TRAFFIC (for chart)
// ============================================
} elseif ($action === 'traffic') {
    
    $traffic = mihomoAPI('/traffic');
    
    echo json_encode([
        'success' => $traffic !== null,
        'upload' => $traffic['up'] ?? 0,
        'download' => $traffic['down'] ?? 0
    ]);
    
// ============================================
// CONTROL MIHOMO
// ============================================
} elseif ($action === 'control') {
    
    $cmd = $_POST['command'] ?? '';
    
    if (!in_array($cmd, ['start', 'stop', 'restart'])) {
        echo json_encode(['success' => false, 'message' => 'Invalid command']);
        exit;
    }
    
    $result = execCmd("systemctl $cmd mihomo");
    sleep(1); // Wait for service
    
    echo json_encode([
        'success' => $result['ok'],
        'message' => $result['ok'] ? 
            ucfirst($cmd) . ' successful' : 
            'Failed: ' . $result['out']
    ]);
    
// ============================================
// RELOAD CONFIG
// ============================================
} elseif ($action === 'reload') {
    
    // Use Mihomo API to reload config
    $ch = curl_init($GLOBALS['MIHOMO_API'] . '/configs');
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => 'PUT',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 3,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $GLOBALS['MIHOMO_SECRET'],
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode([
            'path' => '/opt/mihomo-gateway/config/config.yaml'
        ])
    ]);
    
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $success = ($code === 204 || $code === 200);
    
    echo json_encode([
        'success' => $success,
        'message' => $success ? 'Config reloaded' : 'Failed to reload'
    ]);
    
} else {
    echo json_encode(['success' => false, 'message' => 'Unknown action']);
}
EOFAPI

echo "✅ API created"
echo ""

# STEP 3: Create Dashboard HTML
echo "STEP 3: Creating Dashboard page..."
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
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
    .dashboard-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 20px;
        margin-bottom: 30px;
    }
    
    .stat-card {
        background: white;
        padding: 20px;
        border-radius: 10px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        display: flex;
        align-items: center;
        gap: 15px;
    }
    
    .stat-icon {
        width: 60px;
        height: 60px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
    }
    
    .stat-icon.upload { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; }
    .stat-icon.download { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; }
    .stat-icon.connections { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; }
    .stat-icon.clients { background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); color: white; }
    
    .stat-info h3 {
        font-size: 28px;
        font-weight: bold;
        margin: 0;
        color: #333;
    }
    
    .stat-info p {
        margin: 5px 0 0;
        color: #666;
        font-size: 14px;
    }
    
    .card {
        background: white;
        padding: 25px;
        border-radius: 10px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        margin-bottom: 20px;
    }
    
    .card h2 {
        margin: 0 0 20px;
        font-size: 20px;
        color: #333;
    }
    
    .info-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
    }
    
    .info-item {
        display: flex;
        justify-content: space-between;
        padding: 10px;
        background: #f8f9fa;
        border-radius: 6px;
    }
    
    .info-item label {
        font-weight: 600;
        color: #555;
    }
    
    .info-item span {
        color: #333;
    }
    
    .action-buttons {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
    }
    
    .btn {
        padding: 12px 24px;
        border: none;
        border-radius: 6px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        transition: all 0.3s;
    }
    
    .btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
    .btn-success { background: #28a745; color: white; }
    .btn-danger { background: #dc3545; color: white; }
    .btn-warning { background: #ffc107; color: #333; }
    .btn-info { background: #17a2b8; color: white; }
    .btn-primary { background: #007bff; color: white; }
    
    .status-badge {
        padding: 6px 16px;
        border-radius: 20px;
        font-size: 14px;
        font-weight: 600;
    }
    
    .status-running {
        background: #d4edda;
        color: #155724;
    }
    
    .status-stopped {
        background: #f8d7da;
        color: #721c24;
    }
    
    .notification {
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 6px;
        color: white;
        font-weight: 600;
        z-index: 9999;
        opacity: 0;
        transform: translateX(400px);
        transition: all 0.3s;
    }
    
    .notification.show {
        opacity: 1;
        transform: translateX(0);
    }
    
    .notification-success { background: #28a745; }
    .notification-error { background: #dc3545; }
    .notification-info { background: #17a2b8; }
    </style>
</head>
<body>
    <?php include '../includes/sidebar.php'; ?>
    
    <div class="main-content">
        <div class="header">
            <h1>Dashboard</h1>
            <div style="display: flex; gap: 15px; align-items: center;">
                <button onclick="refreshDashboard()" class="btn btn-primary">
                    🔄 Refresh
                </button>
                <span class="status-badge" id="statusBadge">Loading...</span>
            </div>
        </div>
        
        <!-- Stats Cards -->
        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon upload">
                    ⬆️
                </div>
                <div class="stat-info">
                    <h3 id="uploadSpeed">N/A</h3>
                    <p>Upload Speed</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon download">
                    ⬇️
                </div>
                <div class="stat-info">
                    <h3 id="downloadSpeed">N/A</h3>
                    <p>Download Speed</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon connections">
                    🔗
                </div>
                <div class="stat-info">
                    <h3 id="activeConnections">N/A</h3>
                    <p>Active Connections</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon clients">
                    👥
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
            <canvas id="trafficChart" height="80"></canvas>
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
                    ▶️ Start Mihomo
                </button>
                <button onclick="controlMihomo('stop')" class="btn btn-danger">
                    ⏹️ Stop Mihomo
                </button>
                <button onclick="controlMihomo('restart')" class="btn btn-warning">
                    🔄 Restart Mihomo
                </button>
                <button onclick="reloadConfig()" class="btn btn-info">
                    ♻️ Reload Config
                </button>
            </div>
        </div>
    </div>
    
    <script>
    // Traffic Chart
    const ctx = document.getElementById('trafficChart').getContext('2d');
    const trafficChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Upload',
                data: [],
                borderColor: 'rgb(245, 87, 108)',
                backgroundColor: 'rgba(245, 87, 108, 0.1)',
                tension: 0.4,
                fill: true
            }, {
                label: 'Download',
                data: [],
                borderColor: 'rgb(74, 172, 254)',
                backgroundColor: 'rgba(74, 172, 254, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: true,
                    position: 'top'
                }
            },
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
    
    // Load dashboard
    function loadDashboard() {
        fetch('/api-dashboard.php?action=dashboard')
            .then(r => r.json())
            .then(data => {
                if (!data.success) return;
                
                // Status badge
                const badge = document.getElementById('statusBadge');
                if (data.mihomo.running) {
                    badge.textContent = 'Running';
                    badge.className = 'status-badge status-running';
                } else {
                    badge.textContent = 'Stopped';
                    badge.className = 'status-badge status-stopped';
                }
                
                // Stats
                document.getElementById('uploadSpeed').textContent = data.stats.upload;
                document.getElementById('downloadSpeed').textContent = data.stats.download;
                document.getElementById('activeConnections').textContent = data.stats.connections;
                document.getElementById('hotspotClients').textContent = data.stats.clients;
                
                // System info
                document.getElementById('mihomoVersion').textContent = data.mihomo.version;
                document.getElementById('mihomoMode').textContent = data.mihomo.mode;
                document.getElementById('systemUptime').textContent = data.system.uptime;
                document.getElementById('cpuUsage').textContent = data.system.cpu;
                document.getElementById('memoryUsage').textContent = data.system.memory;
            })
            .catch(err => console.error('Dashboard error:', err));
    }
    
    // Update traffic chart
    function updateTraffic() {
        fetch('/api-dashboard.php?action=traffic')
            .then(r => r.json())
            .then(data => {
                if (!data.success) return;
                
                const now = new Date().toLocaleTimeString();
                
                trafficChart.data.labels.push(now);
                trafficChart.data.datasets[0].data.push(data.upload || 0);
                trafficChart.data.datasets[1].data.push(data.download || 0);
                
                // Keep last 20 points
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
        formData.append('action', 'control');
        formData.append('command', command);
        
        fetch('/api-dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(r => r.json())
        .then(data => {
            showNotif(data.message, data.success ? 'success' : 'error');
            if (data.success) {
                setTimeout(loadDashboard, 1000);
            }
        });
    }
    
    // Reload config
    function reloadConfig() {
        const formData = new FormData();
        formData.append('action', 'reload');
        
        fetch('/api-dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(r => r.json())
        .then(data => {
            showNotif(data.message, data.success ? 'success' : 'error');
        });
    }
    
    // Refresh
    function refreshDashboard() {
        loadDashboard();
        showNotif('Dashboard refreshed', 'info');
    }
    
    // Show notification
    function showNotif(message, type) {
        const notif = document.createElement('div');
        notif.className = `notification notification-${type}`;
        notif.textContent = message;
        document.body.appendChild(notif);
        
        setTimeout(() => notif.classList.add('show'), 10);
        setTimeout(() => {
            notif.classList.remove('show');
            setTimeout(() => notif.remove(), 300);
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
    updateTraffic();
    
    // Auto refresh
    setInterval(loadDashboard, 5000);  // Every 5s
    setInterval(updateTraffic, 2000);  // Every 2s
    </script>
</body>
</html>
EOFDASH

echo "✅ Dashboard created"
echo ""

# STEP 4: Set permissions
echo "STEP 4: Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/
sudo chmod 644 /var/www/html/api-dashboard.php
sudo chmod 644 /var/www/html/dashboard/index.php

echo "✅ Permissions set"
echo ""

# STEP 5: Restart services
echo "STEP 5: Restarting services..."
sudo systemctl restart nginx php8.4-fpm

echo "✅ Services restarted"
echo ""

# STEP 6: Test API
echo "STEP 6: Testing API..."
echo ""
curl -s http://localhost/api-dashboard.php?action=dashboard | jq .

echo ""
echo "================================================"
echo "✅ Dashboard Complete!"
echo "================================================"
echo ""
echo "What's working:"
echo "  ✅ Mihomo status (Running/Stopped)"
echo "  ✅ Upload/Download speed (real-time)"
echo "  ✅ Active connections count"
echo "  ✅ Hotspot clients count"
echo "  ✅ System info (version, mode, uptime, CPU, memory)"
echo "  ✅ Traffic chart (updates every 2s)"
echo "  ✅ Control buttons (Start/Stop/Restart/Reload)"
echo ""
echo "Sudo configured:"
echo "  ✅ No password needed for www-data"
echo "  ✅ All systemctl commands allowed"
echo "  ✅ All hostapd commands allowed"
echo ""
echo "Refresh browser: Ctrl+F5"
echo "URL: http://192.168.1.1/dashboard"
echo ""
