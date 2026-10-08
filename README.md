<div align="center">

# 🐕 System Watchdog & Auto-Healer

**A lightweight, pluggable health-monitoring and auto-recovery daemon for Linux.**  
*Fixes network connectivity drops, monitors local services, and heals systems without rebooting.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

</div>

---

## ⚡ The Problem

On many Linux machines (especially systems with **Realtek r8169/r8168** Ethernet controllers, unstable Wi-Fi adapters, or fluctuating DHCP leases), network connectivity occasionally drops.

By default, NetworkManager attempts to reconnect 4 times and then gives up, forcing users to **reboot their entire computer** just to regain internet connectivity.

## 💡 The Solution

**System Watchdog** runs silently in the background:
1. **Health Checks:** Monitors network connectivity and critical services every 4 seconds.
2. **Debounce Timer (4s):** When a drop occurs, it waits a configurable **4-second confirmation timer** to prevent false alarms from temporary network blips.
3. **Escalating Auto-Recovery:** If still down, it automatically reactivates the network profile, bounces the interface, and cycles networking subsystems — **restoring full connectivity in seconds without a reboot**.
4. **Pluggable Architecture:** You can effortlessly drop in new custom checks (APIs, Docker, Databases) and actions (restarting containers, running hooks, sending webhooks).

---

## 📁 Repository Structure

```text
system-watchdog/
├── bin/
│   └── watchdog            # Core CLI and daemon orchestrator
├── checks/                 # Pluggable health checks (*.sh)
│   ├── 10-internet.sh      # Pings DNS/gateway + checks NetworkManager
│   ├── 20-docker.sh.example# Example: Docker container check
│   └── 30-http-api.sh.example # Example: Backend API / webhook check
├── actions/                # Pluggable recovery actions (*.sh)
│   ├── 10-reconnect-network.sh # Re-activates network profile & interface
│   ├── 20-notify.sh        # Cinnamon / GNOME desktop notifications
│   ├── 30-flush-dns.sh.example # Example: DNS cache flusher
│   └── 40-restart-service.sh.example # Example: Service / container restarter
├── templates/              # Boilerplate templates for new modules
│   ├── check-template.sh
│   └── action-template.sh
├── dashboard/              # Standalone visual web dashboard
│   └── index.html
├── autostart/              # Desktop session autostart entry
├── systemd/                # Optional systemd user service
├── config.conf.example     # Configuration template
├── install.sh              # 1-command installer
├── uninstall.sh            # Clean uninstaller
└── README.md
```

---

## 🚀 Quick Start

### 1. Installation
Clone the repository and run the installer:
```bash
git clone https://github.com/<your-username>/system-watchdog.git
cd system-watchdog
./install.sh
```

The installer will:
- Link the `watchdog` CLI into `~/.local/bin/watchdog`
- Configure desktop autostart so it launches on boot/login
- Place the visual dashboard on your Desktop
- Add convenient shell aliases (`watchdog`, `reconnect`, `net-status`)
- Start the watchdog daemon immediately

---

## 🛠️ CLI Quick Reference

| Command | Description |
|---|---|
| `watchdog status` | Check running state (PID), active modules, and recent logs |
| `watchdog test` | Run all health checks once and print `[PASSED]` / `[FAILED]` |
| `watchdog reconnect` | Trigger recovery actions immediately without waiting |
| `watchdog list` | List all installed check and action modules |
| `watchdog logs` | Stream live daemon logs (`tail -f`) |
| `watchdog start` | Start the background daemon |
| `watchdog stop` | Stop the background daemon |
| `watchdog restart` | Restart the daemon (reloads config and new modules) |
| `watchdog new check <name>` | Scaffold a new health check script |
| `watchdog new action <name>` | Scaffold a new recovery action script |

---

## 🧩 Adding Custom Features

### 1. Add a New Health Check (e.g. Check an API, Database, or VPN)
Run:
```bash
watchdog new check my-api
```
Edit `checks/my-api.sh`:
```bash
#!/usr/bin/env bash
check_name="My API Health"
check_description="Verifies backend API on port 3000 is healthy"

check_run() {
    # Return 0 for healthy, non-zero for failing
    curl -sf http://localhost:3000/health >/dev/null 2>&1
    return $?
}
```
Test your check immediately:
```bash
watchdog test
```

### 2. Add a Custom Recovery Action (e.g. Restart Docker Container)
Run:
```bash
watchdog new action restart-my-app
```
Edit `actions/restart-my-app.sh`:
```bash
#!/usr/bin/env bash
action_name="Restart App Container"

action_run() {
    local failed_check="$1"   # Name of the failed check
    watchdog_log "Healing action running for: $failed_check"

    # Put your healing logic here:
    docker restart my-app-container 2>/dev/null || true
    return 0
}
```

---

## ⚙️ Configuration (`config.conf`)

Customize settings in `config.conf`:
```bash
# Timing (seconds)
CHECK_INTERVAL=4             # Frequency of routine health checks
FAIL_CONFIRM_DELAY=4         # Delay timer to verify failure before taking action

# Target endpoints for 10-internet.sh
PING_TARGETS=("1.1.1.1" "8.8.8.8" "192.168.29.1")

# Desktop Notifications
NOTIFY_ON_RECOVERY=true      # Send desktop notifications on recovery
```

---

## 🖥️ Visual Web Dashboard
Double-click `dashboard/index.html` (or the shortcut created on your Desktop) to open the interactive status dashboard in your browser.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
