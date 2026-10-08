#!/usr/bin/env bash
# ==============================================================================
# System Watchdog & Auto-Healer - Uninstaller
# ==============================================================================

echo "Stopping and uninstalling System Watchdog..."

# 1. Stop daemon if running
if command -v watchdog >/dev/null 2>&1; then
    watchdog stop 2>/dev/null || true
fi

# 2. Remove symlinks & autostart
rm -f "$HOME/.local/bin/watchdog"
rm -f "$HOME/.config/autostart/system-watchdog.desktop"
rm -f "$HOME/Desktop/System_Watchdog_Dashboard.html"

read -p "Do you also want to remove your config and logs in ~/.config/system-watchdog? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/system-watchdog"
    echo "Configuration directory removed."
fi

echo "Uninstallation complete."
