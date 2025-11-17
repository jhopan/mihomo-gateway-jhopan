<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mihomo Gateway - Control Panel</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <?php
    session_start();
    
    // Simple authentication
    if (!isset($_SESSION['logged_in']) && !isset($_POST['login'])) {
        include 'login.php';
        exit;
    }
    
    if (isset($_POST['login'])) {
        $username = $_POST['username'] ?? '';
        $password = $_POST['password'] ?? '';
        
        // Default credentials (change in production!)
        if ($username === 'admin' && $password === 'admin123') {
            $_SESSION['logged_in'] = true;
            $_SESSION['username'] = $username;
        } else {
            $error = "Invalid credentials!";
            include 'login.php';
            exit;
        }
    }
    
    if (isset($_GET['logout'])) {
        session_destroy();
        header('Location: index.php');
        exit;
    }
    
    // Configuration
    $mihomo_api = 'http://127.0.0.1:9090';
    $mihomo_secret = ''; // Add your secret if configured
    ?>
    
    <div class="container">
        <!-- Sidebar -->
        <aside class="sidebar">
            <div class="logo">
                <h2>🚀 Mihomo Gateway</h2>
            </div>
            
            <nav class="nav-menu">
                <a href="#dashboard" class="nav-item active" data-page="dashboard">
                    <span class="icon">📊</span>
                    <span>Dashboard</span>
                </a>
                <a href="#proxies" class="nav-item" data-page="proxies">
                    <span class="icon">🌐</span>
                    <span>Proxies</span>
                </a>
                <a href="#rules" class="nav-item" data-page="rules">
                    <span class="icon">📋</span>
                    <span>Rules</span>
                </a>
                <a href="#connections" class="nav-item" data-page="connections">
                    <span class="icon">🔗</span>
                    <span>Connections</span>
                </a>
                <a href="#hotspot" class="nav-item" data-page="hotspot">
                    <span class="icon">📡</span>
                    <span>Hotspot</span>
                </a>
                <a href="#interfaces" class="nav-item" data-page="interfaces">
                    <span class="icon">🔌</span>
                    <span>Interfaces</span>
                </a>
                <a href="#traffic" class="nav-item" data-page="traffic">
                    <span class="icon">📈</span>
                    <span>Traffic Monitor</span>
                </a>
                <a href="#clients" class="nav-item" data-page="clients">
                    <span class="icon">👥</span>
                    <span>Connected Clients</span>
                </a>
                <a href="#speedtest" class="nav-item" data-page="speedtest">
                    <span class="icon">🚀</span>
                    <span>Speed Test</span>
                </a>
                <a href="#dashboard-ext" class="nav-item" data-page="dashboard-ext">
                    <span class="icon">🎛️</span>
                    <span>External Dashboard</span>
                </a>
                <a href="filemanager.php" class="nav-item" target="_blank">
                    <span class="icon">📁</span>
                    <span>File Manager</span>
                </a>
                <a href="#settings" class="nav-item" data-page="settings">
                    <span class="icon">⚙️</span>
                    <span>Settings</span>
                </a>
                <a href="#logs" class="nav-item" data-page="logs">
                    <span class="icon">📄</span>
                    <span>Logs</span>
                </a>
            </nav>
            
            <div class="sidebar-footer">
                <p>Logged in as: <strong><?php echo $_SESSION['username']; ?></strong></p>
                <a href="?logout" class="btn-logout">Logout</a>
            </div>
        </aside>
        
        <!-- Main Content -->
        <main class="main-content">
            <!-- Header -->
            <header class="header">
                <h1 id="page-title">Dashboard</h1>
                <div class="header-actions">
                    <button class="btn btn-primary" id="refresh-btn">🔄 Refresh</button>
                    <div class="status-indicator" id="mihomo-status">
                        <span class="status-dot"></span>
                        <span class="status-text">Checking...</span>
                    </div>
                </div>
            </header>
            
            <!-- Page Content -->
            <div class="content" id="page-content">
                <!-- Dashboard Page -->
                <div class="page-view" id="dashboard-page">
                    <!-- Stats Cards -->
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-icon">⬆️</div>
                            <div class="stat-info">
                                <h3 id="upload-speed">0 KB/s</h3>
                                <p>Upload Speed</p>
                            </div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-icon">⬇️</div>
                            <div class="stat-info">
                                <h3 id="download-speed">0 KB/s</h3>
                                <p>Download Speed</p>
                            </div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-icon">🔗</div>
                            <div class="stat-info">
                                <h3 id="active-connections">0</h3>
                                <p>Active Connections</p>
                            </div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-icon">📱</div>
                            <div class="stat-info">
                                <h3 id="hotspot-clients">0</h3>
                                <p>Hotspot Clients</p>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Traffic Chart -->
                    <div class="card">
                        <div class="card-header">
                            <h2>Real-time Traffic</h2>
                        </div>
                        <div class="card-body">
                            <canvas id="traffic-chart"></canvas>
                        </div>
                    </div>
                    
                    <!-- System Info -->
                    <div class="card">
                        <div class="card-header">
                            <h2>System Information</h2>
                        </div>
                        <div class="card-body">
                            <div id="system-info" class="info-grid">
                                <div class="info-item">
                                    <span class="info-label">Mihomo Version:</span>
                                    <span class="info-value" id="mihomo-version">-</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">Mode:</span>
                                    <span class="info-value" id="mihomo-mode">-</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">System Uptime:</span>
                                    <span class="info-value" id="system-uptime">-</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">CPU Usage:</span>
                                    <span class="info-value" id="cpu-usage">-</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">Memory Usage:</span>
                                    <span class="info-value" id="memory-usage">-</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Quick Actions -->
                    <div class="card">
                        <div class="card-header">
                            <h2>Quick Actions</h2>
                        </div>
                        <div class="card-body">
                            <div class="action-buttons">
                                <button class="btn btn-success" onclick="controlMihomo('start')">▶️ Start Mihomo</button>
                                <button class="btn btn-danger" onclick="controlMihomo('stop')">⏹️ Stop Mihomo</button>
                                <button class="btn btn-warning" onclick="controlMihomo('restart')">🔄 Restart Mihomo</button>
                                <button class="btn btn-info" onclick="reloadConfig()">♻️ Reload Config</button>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Other pages will be loaded dynamically -->
                <div class="page-view" id="proxies-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Proxy Management</h2>
                            <button class="btn btn-primary" onclick="showAddProxyModal()">➕ Add Proxy</button>
                        </div>
                        <div class="card-body">
                            <div id="proxies-list"></div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="rules-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Rules Management</h2>
                            <button class="btn btn-primary" onclick="showAddRuleModal()">➕ Add Rule</button>
                        </div>
                        <div class="card-body">
                            <div id="rules-list"></div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="connections-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Active Connections</h2>
                            <button class="btn btn-danger" onclick="closeAllConnections()">❌ Close All</button>
                        </div>
                        <div class="card-body">
                            <div id="connections-list"></div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="hotspot-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Hotspot Control</h2>
                        </div>
                        <div class="card-body">
                            <div id="hotspot-control"></div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <h2>Hotspot Configuration</h2>
                        </div>
                        <div class="card-body">
                            <form id="hotspot-config-form">
                                <div class="form-group">
                                    <label for="hotspot-ssid">SSID (Network Name)</label>
                                    <input type="text" id="hotspot-ssid" name="ssid" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="hotspot-password">Password (min 8 characters)</label>
                                    <input type="password" id="hotspot-password" name="password" minlength="8">
                                    <small>Leave empty to keep current password</small>
                                </div>
                                
                                <div class="form-group">
                                    <label for="hotspot-channel">WiFi Channel</label>
                                    <select id="hotspot-channel" name="channel">
                                        <option value="auto">Auto (Recommended)</option>
                                        <option value="1">1 (2412 MHz)</option>
                                        <option value="6">6 (2437 MHz)</option>
                                        <option value="11">11 (2462 MHz)</option>
                                        <option value="36">36 (5180 MHz)</option>
                                        <option value="40">40 (5200 MHz)</option>
                                        <option value="44">44 (5220 MHz)</option>
                                        <option value="48">48 (5240 MHz)</option>
                                    </select>
                                    <small>Auto will select the best channel automatically</small>
                                </div>
                                
                                <button type="submit" class="btn btn-primary">Save Configuration</button>
                            </form>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="interfaces-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Network Interfaces</h2>
                        </div>
                        <div class="card-body">
                            <div id="interfaces-list"></div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="traffic-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Traffic Statistics</h2>
                        </div>
                        <div class="card-body">
                            <canvas id="traffic-history-chart"></canvas>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="dashboard-ext-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>External Dashboard</h2>
                            <div class="dashboard-selector">
                                <button class="btn btn-primary" onclick="loadExternalDashboard('yacd')">Load Yacd</button>
                                <button class="btn btn-primary" onclick="loadExternalDashboard('metacube')">Load MetaCubeX</button>
                                <button class="btn btn-secondary" onclick="openDashboardNewTab()">Open in New Tab</button>
                            </div>
                        </div>
                        <div class="card-body" style="padding:0;">
                            <div id="dashboard-container">
                                <div class="dashboard-placeholder">
                                    <h3>Select a dashboard to view</h3>
                                    <p>Choose Yacd or MetaCubeX dashboard above</p>
                                    <div class="dashboard-info">
                                        <div class="info-box">
                                            <h4>🎯 Yacd Dashboard</h4>
                                            <p>Yet Another Clash Dashboard - Clean and simple interface</p>
                                        </div>
                                        <div class="info-box">
                                            <h4>🎛️ MetaCubeX Dashboard</h4>
                                            <p>Advanced dashboard with more features and controls</p>
                                        </div>
                                    </div>
                                </div>
                                <iframe id="external-dashboard-frame" style="display:none; width:100%; height:800px; border:none;"></iframe>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="settings-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>Settings</h2>
                        </div>
                        <div class="card-body">
                            <div id="settings-form"></div>
                        </div>
                    </div>
                </div>
                
                <div class="page-view" id="logs-page" style="display:none;">
                    <div class="card">
                        <div class="card-header">
                            <h2>System Logs</h2>
                            <button class="btn btn-secondary" onclick="refreshLogs()">🔄 Refresh</button>
                        </div>
                        <div class="card-body">
                            <div id="logs-content" class="logs-container"></div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <!-- Notification Toast -->
    <div id="toast" class="toast"></div>
    
    <!-- Modal Container -->
    <div id="modal" class="modal"></div>
    
    <script src="assets/js/main.js"></script>
</body>
</html>
