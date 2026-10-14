#!/usr/bin/env bash
# ==============================================================================
# System Watchdog & Auto-Healer - Installer
# Compatible with Arch Linux, Debian, Ubuntu, Fedora, openSUSE, etc.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_DIR="$HOME/.config/system-watchdog"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
DESKTOP_DIR="$HOME/Desktop"

echo "=================================================="
echo "  Installing System Watchdog & Auto-Healer        "
echo "=================================================="

# 1. Create target directories
mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$AUTOSTART_DIR" "$SYSTEMD_USER_DIR"

# 2. Make scripts executable
chmod +x "$SCRIPT_DIR/bin/watchdog"
chmod +x "$SCRIPT_DIR"/checks/*.sh* "$SCRIPT_DIR"/actions/*.sh* "$SCRIPT_DIR"/templates/*.sh* 2>/dev/null || true

# 3. Install core files to ~/.config/system-watchdog if different
if [ "$SCRIPT_DIR" != "$CONFIG_DIR" ]; then
    echo "• Copying configurations and modules to $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR/checks" "$CONFIG_DIR/actions" "$CONFIG_DIR/templates" "$CONFIG_DIR/logs"
    
    # Don't overwrite existing config if present
    if [ ! -f "$CONFIG_DIR/config.conf" ]; then
        cp "$SCRIPT_DIR/config.conf.example" "$CONFIG_DIR/config.conf"
    fi
    
    cp -u "$SCRIPT_DIR/checks"/* "$CONFIG_DIR/checks/" 2>/dev/null || true
    cp -u "$SCRIPT_DIR/actions"/* "$CONFIG_DIR/actions/" 2>/dev/null || true
    cp -u "$SCRIPT_DIR/templates"/* "$CONFIG_DIR/templates/" 2>/dev/null || true
    cp "$SCRIPT_DIR/bin/watchdog" "$CONFIG_DIR/watchdog"
    chmod +x "$CONFIG_DIR/watchdog"
fi

# 4. Symlink CLI command to ~/.local/bin/watchdog
echo "• Linking 'watchdog' CLI into $BIN_DIR..."
ln -sf "$SCRIPT_DIR/bin/watchdog" "$BIN_DIR/watchdog"

# 5. Set up autostart entry (for desktop environments: GNOME, KDE, Cinnamon, XFCE)
echo "• Setting up desktop autostart..."
if [ -f "$SCRIPT_DIR/autostart/system-watchdog.desktop" ]; then
    cp "$SCRIPT_DIR/autostart/system-watchdog.desktop" "$AUTOSTART_DIR/system-watchdog.desktop"
fi

# 6. Set up systemd user service (ideal for Arch Linux, Hyprland, Sway, i3)
echo "• Setting up systemd user service..."
if [ -f "$SCRIPT_DIR/systemd/system-watchdog.service" ]; then
    cp "$SCRIPT_DIR/systemd/system-watchdog.service" "$SYSTEMD_USER_DIR/system-watchdog.service"
    if systemctl --user status >/dev/null 2>&1; then
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable system-watchdog.service 2>/dev/null || true
    fi
fi

# 7. Set up desktop dashboard & shortcuts if Desktop exists
if [ -d "$DESKTOP_DIR" ]; then
    echo "• Adding Dashboard to Desktop folder..."
    cp "$SCRIPT_DIR/dashboard/index.html" "$DESKTOP_DIR/System_Watchdog_Dashboard.html" 2>/dev/null || true
fi

# 8. Add bash/zsh aliases if not already present
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ] && ! grep -q "alias watchdog=" "$rc_file"; then
        echo "• Adding aliases to $rc_file..."
        cat << 'EOF' >> "$rc_file"

# System Watchdog shortcuts
alias watchdog="$HOME/.local/bin/watchdog"
alias reconnect="$HOME/.local/bin/watchdog reconnect"
alias fix-dns="$HOME/.local/bin/watchdog fix-dns"
alias net-status="$HOME/.local/bin/watchdog status"
EOF
    elif [ -f "$rc_file" ] && ! grep -q "alias fix-dns=" "$rc_file"; then
        echo "• Adding fix-dns alias to $rc_file..."
        echo 'alias fix-dns="$HOME/.local/bin/watchdog fix-dns"' >> "$rc_file"
    fi
done

# 9. Start Watchdog Daemon
echo "• Starting System Watchdog daemon..."
"$BIN_DIR/watchdog" restart

echo ""
echo "=================================================="
echo "  Installation Successful! 🎉                    "
echo "=================================================="
echo "Run 'watchdog status' to check daemon status."
echo "Run 'watchdog test' to test all health checks."
echo "Run 'watchdog --help' to see all commands."
