<?php
/**
 * Tiny File Manager Integration for Mihomo Gateway
 * Restricted access to /etc/mihomo directory only
 */

// Security check
session_start();

// Configuration
define('FM_ROOT_PATH', '/etc/mihomo');
define('FM_ROOT_URL', '/etc/mihomo');
define('FM_READONLY', false);
define('FM_IS_WIN', false);

// Allowed file extensions for editing
$allowed_file_extensions = 'yaml,yml,txt,conf,json,md,sh';

// Authentication (use same as Mihomo UI)
$auth_users = array(
    'admin' => password_hash('admin123', PASSWORD_DEFAULT) // Change this!
);

// Check if user is logged in (via main Mihomo UI)
if (!isset($_SESSION['mihomo_logged_in']) || $_SESSION['mihomo_logged_in'] !== true) {
    header('Location: ../index.php');
    exit;
}

// Current directory
$current_dir = isset($_GET['p']) ? $_GET['p'] : '';
$current_dir = str_replace('..', '', $current_dir); // Prevent directory traversal
$full_path = FM_ROOT_PATH . '/' . $current_dir;

// Ensure path is within allowed directory
if (strpos(realpath($full_path), realpath(FM_ROOT_PATH)) !== 0) {
    die('Access denied!');
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Manager - Mihomo Gateway</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            color: #333;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 24px;
            margin-bottom: 5px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .container {
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .breadcrumb a {
            color: #667eea;
            text-decoration: none;
            margin: 0 5px;
        }
        
        .breadcrumb a:hover {
            text-decoration: underline;
        }
        
        .file-list {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        
        .file-item {
            display: flex;
            align-items: center;
            padding: 15px 20px;
            border-bottom: 1px solid #f0f0f0;
            transition: background 0.2s;
        }
        
        .file-item:hover {
            background: #f8f9fa;
        }
        
        .file-item:last-child {
            border-bottom: none;
        }
        
        .file-icon {
            width: 40px;
            height: 40px;
            margin-right: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f0f0f0;
            border-radius: 5px;
            font-size: 20px;
        }
        
        .file-name {
            flex: 1;
            font-weight: 500;
        }
        
        .file-name a {
            color: #333;
            text-decoration: none;
        }
        
        .file-name a:hover {
            color: #667eea;
        }
        
        .file-size {
            color: #999;
            margin-right: 20px;
            font-size: 14px;
        }
        
        .file-actions {
            display: flex;
            gap: 10px;
        }
        
        .file-actions a {
            padding: 5px 15px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 13px;
            transition: background 0.2s;
        }
        
        .file-actions a:hover {
            background: #5568d3;
        }
        
        .file-actions a.delete {
            background: #e74c3c;
        }
        
        .file-actions a.delete:hover {
            background: #c0392b;
        }
        
        .toolbar {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            display: flex;
            gap: 10px;
        }
        
        .toolbar button {
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.2s;
        }
        
        .toolbar button:hover {
            background: #5568d3;
        }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        
        .back-link:hover {
            text-decoration: underline;
        }
        
        .editor {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        textarea {
            width: 100%;
            min-height: 500px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.6;
        }
        
        .save-btn {
            margin-top: 15px;
            padding: 12px 30px;
            background: #27ae60;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
        }
        
        .save-btn:hover {
            background: #229954;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📁 File Manager</h1>
        <p>Manage Mihomo configuration files</p>
    </div>
    
    <div class="container">
        <a href="../index.php" class="back-link">← Back to Dashboard</a>
        
        <div class="breadcrumb">
            🏠 <a href="?">Home</a>
            <?php
            if ($current_dir) {
                $parts = explode('/', trim($current_dir, '/'));
                $path = '';
                foreach ($parts as $part) {
                    $path .= $part . '/';
                    echo ' / <a href="?p=' . urlencode(trim($path, '/')) . '">' . htmlspecialchars($part) . '</a>';
                }
            }
            ?>
        </div>
        
        <?php if (isset($_GET['edit'])): 
            $file_to_edit = $full_path . '/' . basename($_GET['edit']);
            if (file_exists($file_to_edit) && is_file($file_to_edit)):
        ?>
            <div class="editor">
                <h2>Editing: <?php echo htmlspecialchars(basename($_GET['edit'])); ?></h2>
                <form method="post">
                    <textarea name="content"><?php echo htmlspecialchars(file_get_contents($file_to_edit)); ?></textarea>
                    <br>
                    <button type="submit" name="save" class="save-btn">💾 Save Changes</button>
                </form>
            </div>
            
            <?php
            if (isset($_POST['save'])) {
                file_put_contents($file_to_edit, $_POST['content']);
                echo '<p style="color: green; margin-top: 15px;">✓ File saved successfully!</p>';
            }
            ?>
        <?php 
            endif;
        else: 
        ?>
        
        <div class="toolbar">
            <button onclick="location.reload()">🔄 Refresh</button>
            <button onclick="if(confirm('Restart Mihomo service?')) { window.location.href='../api.php?action=restart_mihomo'; }">🔄 Restart Mihomo</button>
        </div>
        
        <div class="file-list">
            <?php
            // List directories and files
            $items = scandir($full_path);
            
            // Show parent directory link
            if ($current_dir) {
                $parent = dirname($current_dir);
                echo '<div class="file-item">';
                echo '<div class="file-icon">📁</div>';
                echo '<div class="file-name"><a href="?p=' . urlencode($parent) . '">.. (Parent Directory)</a></div>';
                echo '</div>';
            }
            
            foreach ($items as $item) {
                if ($item == '.' || $item == '..') continue;
                
                $item_path = $full_path . '/' . $item;
                $is_dir = is_dir($item_path);
                $file_size = $is_dir ? '-' : formatSize(filesize($item_path));
                
                echo '<div class="file-item">';
                echo '<div class="file-icon">' . ($is_dir ? '📁' : '📄') . '</div>';
                
                if ($is_dir) {
                    $new_path = $current_dir ? $current_dir . '/' . $item : $item;
                    echo '<div class="file-name"><a href="?p=' . urlencode($new_path) . '">' . htmlspecialchars($item) . '</a></div>';
                } else {
                    echo '<div class="file-name">' . htmlspecialchars($item) . '</div>';
                }
                
                echo '<div class="file-size">' . $file_size . '</div>';
                echo '<div class="file-actions">';
                
                if (!$is_dir) {
                    echo '<a href="?p=' . urlencode($current_dir) . '&edit=' . urlencode($item) . '">✏️ Edit</a>';
                    echo '<a href="?p=' . urlencode($current_dir) . '&download=' . urlencode($item) . '">⬇️ Download</a>';
                }
                
                echo '</div>';
                echo '</div>';
            }
            
            function formatSize($bytes) {
                if ($bytes >= 1073741824) {
                    return number_format($bytes / 1073741824, 2) . ' GB';
                } elseif ($bytes >= 1048576) {
                    return number_format($bytes / 1048576, 2) . ' MB';
                } elseif ($bytes >= 1024) {
                    return number_format($bytes / 1024, 2) . ' KB';
                } else {
                    return $bytes . ' B';
                }
            }
            ?>
        </div>
        
        <?php endif; ?>
    </div>
</body>
</html>

<?php
// Handle file download
if (isset($_GET['download'])) {
    $file_to_download = $full_path . '/' . basename($_GET['download']);
    if (file_exists($file_to_download) && is_file($file_to_download)) {
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . basename($file_to_download) . '"');
        header('Content-Length: ' . filesize($file_to_download));
        readfile($file_to_download);
        exit;
    }
}
?>
