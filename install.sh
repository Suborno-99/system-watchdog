#!/usr/bin/env bash
# ==============================================================================
# System Watchdog & Auto-Healer - Installer
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_DIR="$HOME/.config/system-watchdog"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_DIR="$HOME/Desktop"

echo "=================================================="
echo "  Installing System Watchdog & Auto-Healer        "
echo "=================================================="

# 1. Create target directories
mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$AUTOSTART_DIR"

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

# 5. Set up autostart entry
echo "• Setting up desktop autostart..."
if [ -f "$SCRIPT_DIR/autostart/system-watchdog.desktop" ]; then
    cp "$SCRIPT_DIR/autostart/system-watchdog.desktop" "$AUTOSTART_DIR/system-watchdog.desktop"
fi

# 6. Set up desktop dashboard & shortcuts
if [ -d "$DESKTOP_DIR" ]; then
    echo "• Adding Dashboard to Desktop folder..."
    cp "$SCRIPT_DIR/dashboard/index.html" "$DESKTOP_DIR/System_Watchdog_Dashboard.html" 2>/dev/null || true
fi

# 7. Add bash aliases if not already present
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "alias watchdog=" "$HOME/.bashrc"; then
        echo "• Adding aliases to ~/.bashrc..."
        cat << 'EOF' >> "$HOME/.bashrc"

# System Watchdog shortcuts
alias watchdog="$HOME/.local/bin/watchdog"
alias reconnect="$HOME/.local/bin/watchdog reconnect"
alias net-status="$HOME/.local/bin/watchdog status"
EOF
    fi
fi

# 8. Start Watchdog Daemon
echo "• Starting System Watchdog daemon..."
"$BIN_DIR/watchdog" restart

echo ""
echo "=================================================="
echo "  Installation Successful! 🎉                    "
echo "=================================================="
echo "Run 'watchdog status' to check daemon status."
echo "Run 'watchdog test' to test all health checks."
echo "Run 'watchdog --help' to see all commands."
