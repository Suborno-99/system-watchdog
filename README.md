<div align="center">

# 🐕 System Watchdog & Auto-Healer

**A lightweight, pluggable health-monitoring and auto-recovery daemon for Linux.**  
*Fixes network connectivity drops, monitors local services, and heals systems without rebooting.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-Supported-1793d1.svg?logo=arch-linux&logoColor=white)]()
[![Ubuntu / Debian](https://img.shields.io/badge/Ubuntu%20%2F%20Debian-Supported-E95420.svg?logo=ubuntu&logoColor=white)]()
[![Shell](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

</div>

---

## ⚡ The Problem

On Linux systems (especially machines with **Realtek r8169/r8168** Ethernet controllers, volatile Wi-Fi chips, or flaky DHCP leases), network connectivity can suddenly drop.

By default, NetworkManager retries 4 times and gives up, while minimal systems (like Arch with systemd-networkd or dhcpcd) often leave interfaces in a silent stalled state. Users are forced to **reboot their computer** just to regain internet connectivity.

## 💡 The Solution

**System Watchdog** runs in the background and takes care of it:
1. **Health Checks:** Monitors gateway/DNS connectivity and critical services every 4 seconds.
2. **Debounce Timer (4s):** When a drop occurs, it waits a configurable **4-second confirmation timer** to prevent false triggers from transient latency.
3. **Escalating Multi-Backend Recovery:** Restores connectivity in seconds without a reboot.
   - **NetworkManager** (`nmcli` profile reactivation & device bounce)
   - **systemd-networkd** (`networkctl reconfigure`)
   - **Universal Kernel Link Bounce** (`ip link` down/up + DHCP renewal)
4. **Pluggable Architecture:** Effortlessly add custom checks (APIs, Docker, Databases) and actions (restarting containers, running hooks, sending webhooks).

---

## 🐧 Arch Linux Support

System Watchdog is **100% compatible with Arch Linux**:
- **Network Backends:** Works with `NetworkManager`, `systemd-networkd`, or standard `iproute2` / `dhcpcd` / `iwd`.
- **Desktop Environments & Window Managers:** Runs seamlessly on GNOME, KDE Plasma, Cinnamon, XFCE, as well as tiling window managers like **Hyprland**, **Sway**, and **i3** via `systemd --user`.
- **Zsh & Bash:** Automatically detects and configures aliases for both `~/.bashrc` and `~/.zshrc`.
- **Arch Packaging:** Includes a ready-to-build [`PKGBUILD`](PKGBUILD) for native Arch packaging.

### Dependencies on Arch Linux:
```bash
sudo pacman -S --needed bash iproute2 iputils
# Optional (recommended):
sudo pacman -S --needed networkmanager libnotify
```

---

## 🚀 Installation

### Option 1: Universal One-Command Installer (Arch, Debian, Ubuntu, Fedora)
```bash
git clone https://github.com/<your-username>/system-watchdog.git
cd system-watchdog
./install.sh
```

### Option 2: Native Arch Linux Package (`PKGBUILD`)
```bash
git clone https://github.com/<your-username>/system-watchdog.git
cd system-watchdog
makepkg -si
```
Then enable the systemd user service:
```bash
systemctl --user enable --now system-watchdog.service
```

---

## 📁 Repository Structure

```text
system-watchdog/
├── bin/
│   └── watchdog            # Core CLI and daemon orchestrator
├── checks/                 # Pluggable health checks (*.sh)
│   ├── 10-internet.sh      # Pings DNS/gateway + checks NetworkManager/networkd
│   ├── 20-docker.sh.example# Example: Docker container check
│   └── 30-http-api.sh.example # Example: Backend API / webhook check
├── actions/                # Pluggable recovery actions (*.sh)
│   ├── 10-reconnect-network.sh # Multi-backend auto-reconnection
│   ├── 20-notify.sh        # Desktop notifications via notify-send
│   ├── 30-flush-dns.sh.example # Example: DNS cache flusher
│   └── 40-restart-service.sh.example # Example: Service/container restart hook
├── templates/              # Scaffolding templates for new modules
│   ├── check-template.sh
│   └── action-template.sh
├── dashboard/              # Standalone visual web dashboard
│   └── index.html
├── autostart/              # Desktop session autostart entry
├── systemd/                # systemd user service unit
├── PKGBUILD                # Arch Linux package build recipe
├── config.conf.example     # Configuration template
├── install.sh              # Universal installer
├── uninstall.sh            # Clean uninstaller
└── README.md
```

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
```bash
watchdog new action restart-my-app
```
Edit `actions/restart-my-app.sh`:
```bash
#!/usr/bin/env bash
action_name="Restart App Container"

action_run() {
    local failed_check="$1"
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

## 📄 License
This project is licensed under the [MIT License](LICENSE).
