// Mihomo Gateway - Main JavaScript

// Configuration
const MIHOMO_API = "http://127.0.0.1:9090";
const API_SECRET = ""; // Add if configured
const REFRESH_INTERVAL = 2000; // 2 seconds

// Global variables
let trafficChart = null;
let trafficData = {
  upload: [],
  download: [],
  labels: [],
};
let refreshTimer = null;

// Initialize on page load
$(document).ready(function () {
  console.log("Mihomo Gateway UI Loaded");

  // Initialize navigation
  initNavigation();

  // Initialize dashboard
  initDashboard();

  // Start auto-refresh
  startAutoRefresh();

  // Refresh button
  $("#refresh-btn").click(function () {
    refreshCurrentPage();
  });
});

// Navigation
function initNavigation() {
  $(".nav-item").click(function (e) {
    e.preventDefault();

    // Remove active class from all items
    $(".nav-item").removeClass("active");

    // Add active class to clicked item
    $(this).addClass("active");

    // Get page name
    const page = $(this).data("page");

    // Update page title
    const title = $(this).find("span:last").text();
    $("#page-title").text(title);

    // Hide all pages
    $(".page-view").hide();

    // Show selected page
    $(`#${page}-page`).fadeIn();

    // Load page content
    loadPage(page);
  });
}

// Initialize Dashboard
function initDashboard() {
  // Initialize traffic chart
  const ctx = document.getElementById("traffic-chart");
  if (ctx) {
    trafficChart = new Chart(ctx, {
      type: "line",
      data: {
        labels: trafficData.labels,
        datasets: [
          {
            label: "Upload",
            data: trafficData.upload,
            borderColor: "#ef4444",
            backgroundColor: "rgba(239, 68, 68, 0.1)",
            tension: 0.4,
          },
          {
            label: "Download",
            data: trafficData.download,
            borderColor: "#10b981",
            backgroundColor: "rgba(16, 185, 129, 0.1)",
            tension: 0.4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function (value) {
                return formatBytes(value) + "/s";
              },
            },
          },
        },
        plugins: {
          legend: {
            display: true,
            position: "top",
          },
        },
      },
    });
  }

  // Load initial data
  updateDashboard();
}

// Update Dashboard
function updateDashboard() {
  // Check Mihomo status
  checkMihomoStatus();

  // Get traffic
  getTraffic();

  // Get connections
  getConnections();

  // Get system info
  getSystemInfo();

  // Get hotspot clients
  getHotspotClients();
}

// Check Mihomo Status
function checkMihomoStatus() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "status" },
    success: function (response) {
      if (response.success) {
        $("#mihomo-status .status-dot").removeClass("inactive");
        $("#mihomo-status .status-text").text("Running");
      } else {
        $("#mihomo-status .status-dot").addClass("inactive");
        $("#mihomo-status .status-text").text("Stopped");
      }
    },
    error: function () {
      $("#mihomo-status .status-dot").addClass("inactive");
      $("#mihomo-status .status-text").text("Error");
    },
  });
}

// Get Traffic
function getTraffic() {
  $.ajax({
    url: MIHOMO_API + "/traffic",
    method: "GET",
    headers: API_SECRET ? { Authorization: "Bearer " + API_SECRET } : {},
    success: function (data) {
      // Update speed display
      $("#upload-speed").text(formatBytes(data.up) + "/s");
      $("#download-speed").text(formatBytes(data.down) + "/s");

      // Update chart
      if (trafficChart) {
        const now = new Date().toLocaleTimeString();

        trafficData.labels.push(now);
        trafficData.upload.push(data.up);
        trafficData.download.push(data.down);

        // Keep only last 20 data points
        if (trafficData.labels.length > 20) {
          trafficData.labels.shift();
          trafficData.upload.shift();
          trafficData.download.shift();
        }

        trafficChart.update();
      }
    },
    error: function () {
      $("#upload-speed").text("N/A");
      $("#download-speed").text("N/A");
    },
  });
}

// Get Connections
function getConnections() {
  $.ajax({
    url: MIHOMO_API + "/connections",
    method: "GET",
    headers: API_SECRET ? { Authorization: "Bearer " + API_SECRET } : {},
    success: function (data) {
      const count = data.connections ? data.connections.length : 0;
      $("#active-connections").text(count);

      // Update connections page if visible
      if ($("#connections-page").is(":visible")) {
        displayConnections(data.connections);
      }
    },
    error: function () {
      $("#active-connections").text("N/A");
    },
  });
}

// Get System Info
function getSystemInfo() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "system_info" },
    success: function (response) {
      if (response.success) {
        const info = response.data;
        $("#mihomo-version").text(info.version || "N/A");
        $("#mihomo-mode").text(info.mode || "N/A");
        $("#system-uptime").text(info.uptime || "N/A");
        $("#cpu-usage").text(info.cpu + "%" || "N/A");
        $("#memory-usage").text(info.memory + "%" || "N/A");
      }
    },
  });
}

// Get Hotspot Clients
function getHotspotClients() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "hotspot_clients" },
    success: function (response) {
      if (response.success) {
        $("#hotspot-clients").text(response.data.count);
      } else {
        $("#hotspot-clients").text("0");
      }
    },
  });
}

// Control Mihomo
function controlMihomo(action) {
  $.ajax({
    url: "api.php",
    method: "POST",
    data: { action: "control_mihomo", command: action },
    success: function (response) {
      if (response.success) {
        showToast("Success: " + response.message, "success");
        setTimeout(updateDashboard, 2000);
      } else {
        showToast("Error: " + response.message, "error");
      }
    },
    error: function () {
      showToast("Failed to execute command", "error");
    },
  });
}

// Reload Config
function reloadConfig() {
  $.ajax({
    url: "api.php",
    method: "POST",
    data: { action: "reload_config" },
    success: function (response) {
      if (response.success) {
        showToast("Configuration reloaded successfully", "success");
      } else {
        showToast("Failed to reload configuration", "error");
      }
    },
  });
}

// Load Page Content
function loadPage(page) {
  switch (page) {
    case "dashboard":
      updateDashboard();
      break;
    case "proxies":
      loadProxies();
      break;
    case "rules":
      loadRules();
      break;
    case "connections":
      loadConnections();
      break;
    case "hotspot":
      loadHotspot();
      break;
    case "interfaces":
      loadInterfaces();
      break;
    case "traffic":
      loadTrafficHistory();
      break;
    case "settings":
      loadSettings();
      break;
    case "logs":
      loadLogs();
      break;
  }
}

// Load Proxies
function loadProxies() {
  $.ajax({
    url: MIHOMO_API + "/proxies",
    method: "GET",
    headers: API_SECRET ? { Authorization: "Bearer " + API_SECRET } : {},
    success: function (data) {
      displayProxies(data.proxies);
    },
    error: function () {
      $("#proxies-list").html("<p>Failed to load proxies</p>");
    },
  });
}

// Display Proxies
function displayProxies(proxies) {
  let html = '<div class="table-container"><table class="table"><thead><tr>';
  html +=
    "<th>Name</th><th>Type</th><th>Delay</th><th>Status</th><th>Actions</th>";
  html += "</tr></thead><tbody>";

  for (const [name, proxy] of Object.entries(proxies)) {
    if (proxy.type === "Selector" || proxy.type === "URLTest") {
      html += `<tr>
                <td><strong>${name}</strong></td>
                <td><span class="badge badge-info">${proxy.type}</span></td>
                <td>-</td>
                <td>-</td>
                <td><button class="btn btn-primary btn-sm" onclick="selectProxy('${name}')">Select</button></td>
            </tr>`;
    }
  }

  html += "</tbody></table></div>";
  $("#proxies-list").html(html);
}

// Display Connections
function displayConnections(connections) {
  let html = '<div class="table-container"><table class="table"><thead><tr>';
  html +=
    "<th>Source</th><th>Destination</th><th>Proxy</th><th>Upload</th><th>Download</th><th>Actions</th>";
  html += "</tr></thead><tbody>";

  if (connections && connections.length > 0) {
    connections.forEach((conn) => {
      html += `<tr>
                <td>${conn.metadata.sourceIP}:${conn.metadata.sourcePort}</td>
                <td>${conn.metadata.host || conn.metadata.destinationIP}:${
        conn.metadata.destinationPort
      }</td>
                <td>${conn.chains[conn.chains.length - 1] || "DIRECT"}</td>
                <td>${formatBytes(conn.upload)}</td>
                <td>${formatBytes(conn.download)}</td>
                <td><button class="btn btn-danger btn-sm" onclick="closeConnection('${
                  conn.id
                }')">Close</button></td>
            </tr>`;
    });
  } else {
    html +=
      '<tr><td colspan="6" style="text-align:center">No active connections</td></tr>';
  }

  html += "</tbody></table></div>";
  $("#connections-list").html(html);
}

// Load Hotspot
function loadHotspot() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "hotspot_status" },
    success: function (response) {
      displayHotspot(response);
    },
  });

  // Load hotspot configuration
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "get_hotspot_config" },
    success: function (response) {
      if (response.success) {
        $("#hotspot-ssid").val(response.data.ssid);
        $("#hotspot-channel").val(response.data.channel);
      }
    },
  });

  // Setup form handler
  $("#hotspot-config-form")
    .off("submit")
    .on("submit", function (e) {
      e.preventDefault();
      saveHotspotConfig();
    });
}

// Display Hotspot
function displayHotspot(data) {
  let html = '<div class="hotspot-control-panel">';

  if (data.success && data.data.running) {
    html += `
            <div class="alert alert-success">
                <h3>✓ Hotspot is running</h3>
                <p>SSID: <strong>${data.data.ssid}</strong></p>
                <p>Connected Clients: <strong>${data.data.clients}</strong></p>
            </div>
            <div class="action-buttons">
                <button class="btn btn-danger" onclick="controlHotspot('stop')">Stop Hotspot</button>
                <button class="btn btn-warning" onclick="controlHotspot('restart')">Restart Hotspot</button>
            </div>
        `;
  } else {
    html += `
            <div class="alert alert-warning">
                <h3>⚠ Hotspot is not running</h3>
            </div>
            <div class="action-buttons">
                <button class="btn btn-success" onclick="controlHotspot('start')">Start Hotspot</button>
            </div>
        `;
  }

  html += "</div>";
  $("#hotspot-control").html(html);
}

// Control Hotspot
function controlHotspot(action) {
  $.ajax({
    url: "api.php",
    method: "POST",
    data: { action: "control_hotspot", command: action },
    success: function (response) {
      if (response.success) {
        showToast(response.message, "success");
        setTimeout(loadHotspot, 2000);
      } else {
        showToast(response.message, "error");
      }
    },
  });
}

// Load Interfaces
function loadInterfaces() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "interfaces" },
    success: function (response) {
      displayInterfaces(response.data);
    },
  });
}

// Display Interfaces
function displayInterfaces(interfaces) {
  let html = '<div class="table-container"><table class="table"><thead><tr>';
  html +=
    "<th>Interface</th><th>Status</th><th>IP Address</th><th>MAC Address</th>";
  html += "</tr></thead><tbody>";

  if (interfaces && interfaces.length > 0) {
    interfaces.forEach((iface) => {
      const statusBadge =
        iface.status === "UP"
          ? '<span class="badge badge-success">UP</span>'
          : '<span class="badge badge-danger">DOWN</span>';

      html += `<tr>
                <td><strong>${iface.name}</strong></td>
                <td>${statusBadge}</td>
                <td>${iface.ip || "N/A"}</td>
                <td>${iface.mac || "N/A"}</td>
            </tr>`;
    });
  }

  html += "</tbody></table></div>";
  $("#interfaces-list").html(html);
}

// Load Logs
function loadLogs() {
  $.ajax({
    url: "api.php",
    method: "GET",
    data: { action: "logs" },
    success: function (response) {
      if (response.success) {
        $("#logs-content").html("<pre>" + response.data + "</pre>");
      }
    },
  });
}

function refreshLogs() {
  loadLogs();
}

// Utility Functions
function formatBytes(bytes) {
  if (bytes === 0) return "0 B";
  const k = 1024;
  const sizes = ["B", "KB", "MB", "GB", "TB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
}

function showToast(message, type = "info") {
  const toast = $("#toast");
  toast.text(message);
  toast.removeClass("success error warning");
  toast.addClass(type + " show");

  setTimeout(() => {
    toast.removeClass("show");
  }, 3000);
}

// Auto Refresh
function startAutoRefresh() {
  refreshTimer = setInterval(() => {
    const currentPage = $(".nav-item.active").data("page");
    if (currentPage === "dashboard") {
      updateDashboard();
    }
  }, REFRESH_INTERVAL);
}

function stopAutoRefresh() {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }
}

function refreshCurrentPage() {
  const currentPage = $(".nav-item.active").data("page");
  loadPage(currentPage);
  showToast("Page refreshed", "success");
}

// Save Hotspot Config
function saveHotspotConfig() {
  const formData = {
    action: "configure_hotspot",
    ssid: $("#hotspot-ssid").val(),
    password: $("#hotspot-password").val(),
    channel: $("#hotspot-channel").val(),
  };

  $.ajax({
    url: "api.php",
    method: "POST",
    data: formData,
    success: function (response) {
      if (response.success) {
        showToast("Hotspot configuration saved successfully", "success");
        $("#hotspot-password").val(""); // Clear password field
        loadHotspot();
      } else {
        showToast("Error: " + response.message, "error");
      }
    },
    error: function () {
      showToast("Failed to save configuration", "error");
    },
  });
}

// Load External Dashboard
function loadExternalDashboard(type) {
  const frame = $("#external-dashboard-frame");
  const placeholder = $(".dashboard-placeholder");

  let url = "";

  if (type === "yacd") {
    url = "https://yacd.haishan.me/?hostname=127.0.0.1&port=9090";
  } else if (type === "metacube") {
    url = "https://metacubex.github.io/yacd/?hostname=127.0.0.1&port=9090";
  }

  if (url) {
    placeholder.hide();
    frame.attr("src", url).show();
    showToast("Loading " + type + " dashboard...", "info");
  }
}

// Open Dashboard in New Tab
function openDashboardNewTab() {
  const yacdUrl =
    "https://yacd.haishan.me/?hostname=" +
    window.location.hostname +
    "&port=9090";
  window.open(yacdUrl, "_blank");
}

// Cleanup on page unload
$(window).on("beforeunload", function () {
  stopAutoRefresh();
});
