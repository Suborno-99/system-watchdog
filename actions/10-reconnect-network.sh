#!/usr/bin/env bash
# ==============================================================================
# Action: Network Auto-Reconnect & DNS Healer
# Fully compatible with Arch, Debian, Ubuntu, Fedora (NetworkManager, systemd-networkd, ip link)
# ==============================================================================

action_name="Network Auto-Reconnect & DNS Healer"
action_description="Restores network connectivity via NetworkManager, systemd-networkd, DNS-over-TLS healing, or kernel link bounce"

action_run() {
    local failed_check="$1"

    # Only run for internet/connectivity/DNS check failures or manual trigger
    if [ -n "$failed_check" ] && [[ "$failed_check" != *"Internet"* && "$failed_check" != *"Gateway"* && "$failed_check" != *"internet"* && "$failed_check" != *"gateway"* && "$failed_check" != *"DNS"* && "$failed_check" != *"dns"* && "$failed_check" != *"manual"* ]]; then
        return 0
    fi

    # 1. Auto-detect primary network device universally across all Linux distros
    local dev_name=""
    if command -v nmcli >/dev/null 2>&1; then
        dev_name=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | grep -E ':ethernet|:wifi' | head -n1 | cut -d: -f1)
    fi
    if [ -z "$dev_name" ]; then
        dev_name=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -n1)
    fi
    if [ -z "$dev_name" ]; then
        dev_name=$(ip -o link show 2>/dev/null | grep -Ev 'lo:|docker|br-|veth' | awk -F': ' '{print $2}' | head -n1)
    fi
    [ -z "$dev_name" ] && dev_name="${DEFAULT_INTERFACE:-enp2s0}"

    local con_name=""
    if command -v nmcli >/dev/null 2>&1; then
        con_name=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':ethernet|:wifi' | head -n1 | cut -d: -f1)
        [ -z "$con_name" ] && con_name="${DEFAULT_PROFILE:-Profile 1}"
    fi

    flush_dns() {
        if command -v resolvectl >/dev/null 2>&1; then
            resolvectl flush-caches 2>/dev/null || true
        elif command -v systemd-resolve >/dev/null 2>&1; then
            systemd-resolve --flush-caches 2>/dev/null || true
        fi
    }

    heal_dns() {
        local con="$1"
        local dev="$2"
        local dns_servers="${FALLBACK_DNS:-1.1.1.1 1.0.0.1}"
        local dot="${ENABLE_DNS_OVER_TLS:-yes}"
        local ignore_auto="${IGNORE_AUTO_DNS:-yes}"

        watchdog_log "Applying DNS healing (DNS: $dns_servers, DoT: $dot, Ignore Auto-DNS: $ignore_auto)..."

        if command -v nmcli >/dev/null 2>&1 && [ -n "$con" ]; then
            nmcli connection modify "$con" ipv4.dns "$dns_servers" 2>/dev/null || true
            if [ "$ignore_auto" = true ] || [ "$ignore_auto" = "yes" ]; then
                nmcli connection modify "$con" ipv4.ignore-auto-dns yes 2>/dev/null || true
            fi
            if [ "$dot" = true ] || [ "$dot" = "yes" ]; then
                nmcli connection modify "$con" connection.dns-over-tls yes 2>/dev/null || true
            fi
            nmcli connection up "$con" >/dev/null 2>&1 || true
        fi

        flush_dns
    }

    # If failure is specifically DNS (e.g., WAN IP reachable, but DNS queries fail):
    if [[ "$failed_check" == *"DNS"* || "$failed_check" == *"dns"* ]]; then
        watchdog_log "Detected DNS failure on interface '$dev_name'. Attempting targeted DNS auto-heal..."
        heal_dns "$con_name" "$dev_name"
        sleep 2
        if checks_pass; then
            watchdog_log "Reconnected successfully via DNS auto-heal."
            return 0
        fi
    fi

    watchdog_log "Attempting network recovery on interface '$dev_name'..."

    # -------------------------------------------------------------------------
    # METHOD A: NetworkManager (Standard on desktop Arch, Ubuntu, Fedora)
    # -------------------------------------------------------------------------
    if command -v nmcli >/dev/null 2>&1; then
        # Step A1: Profile re-activation
        nmcli connection up "$con_name" >/dev/null 2>&1 || nmcli device connect "$dev_name" >/dev/null 2>&1
        flush_dns
        if [ "${AUTO_DNS_HEAL:-true}" = true ] || [ "${AUTO_DNS_HEAL:-true}" = "yes" ]; then
            heal_dns "$con_name" "$dev_name"
        fi
        sleep 3
        if checks_pass; then
            flush_dns
            watchdog_log "Reconnected successfully via NetworkManager profile activation."
            return 0
        fi

        # Step A2: Soft bounce device
        watchdog_log "Step 1 failed. Bouncing device '$dev_name' via nmcli..."
        nmcli device disconnect "$dev_name" >/dev/null 2>&1
        sleep 2
        nmcli device connect "$dev_name" >/dev/null 2>&1 || nmcli connection up "$con_name" >/dev/null 2>&1
        flush_dns
        if [ "${AUTO_DNS_HEAL:-true}" = true ] || [ "${AUTO_DNS_HEAL:-true}" = "yes" ]; then
            heal_dns "$con_name" "$dev_name"
        fi
        sleep 4
        if checks_pass; then
            flush_dns
            watchdog_log "Reconnected successfully after bouncing device."
            return 0
        fi

        # Step A3: Full NetworkManager networking toggle
        watchdog_log "Step 2 failed. Toggling NetworkManager networking subsystem..."
        nmcli networking off >/dev/null 2>&1
        sleep 2
        nmcli networking on >/dev/null 2>&1
        flush_dns
        if [ "${AUTO_DNS_HEAL:-true}" = true ] || [ "${AUTO_DNS_HEAL:-true}" = "yes" ]; then
            heal_dns "$con_name" "$dev_name"
        fi
        sleep 5
        if checks_pass; then
            flush_dns
            watchdog_log "Reconnected successfully after networking toggle."
            return 0
        fi
    fi

    # -------------------------------------------------------------------------
    # METHOD B: systemd-networkd (Standard on minimal Arch Linux installs)
    # -------------------------------------------------------------------------
    if command -v networkctl >/dev/null 2>&1; then
        watchdog_log "Attempting recovery via networkctl reconfigure '$dev_name'..."
        networkctl reconfigure "$dev_name" 2>/dev/null || networkctl renew "$dev_name" 2>/dev/null
        flush_dns
        if [ "${AUTO_DNS_HEAL:-true}" = true ] || [ "${AUTO_DNS_HEAL:-true}" = "yes" ]; then
            heal_dns "$con_name" "$dev_name"
        fi
        sleep 3
        if checks_pass; then
            watchdog_log "Reconnected successfully via systemd-networkd."
            return 0
        fi
    fi

    # -------------------------------------------------------------------------
    # METHOD C: Universal Kernel Link Bounce (ip link + DHCP renewal)
    # -------------------------------------------------------------------------
    if command -v ip >/dev/null 2>&1 && [ -n "$dev_name" ]; then
        watchdog_log "Attempting kernel link bounce on '$dev_name'..."
        ip link set "$dev_name" down 2>/dev/null || true
        sleep 2
        ip link set "$dev_name" up 2>/dev/null || true

        # Renew DHCP lease if client is available
        if command -v dhcpcd >/dev/null 2>&1; then
            dhcpcd -n "$dev_name" 2>/dev/null || true
        elif command -v dhclient >/dev/null 2>&1; then
            dhclient -r "$dev_name" 2>/dev/null || true
            dhclient "$dev_name" 2>/dev/null || true
        fi

        flush_dns
        sleep 3
        if checks_pass; then
            watchdog_log "Reconnected successfully via kernel link bounce."
            return 0
        fi
    fi

    watchdog_log "Recovery attempts completed without confirmed recovery; will retry next cycle."
    return 1
}
