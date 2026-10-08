#!/usr/bin/env bash
# ==============================================================================
# Action: Network Auto-Reconnect
# ==============================================================================

action_name="Network Auto-Reconnect"
action_description="Reactivates active NetworkManager connection and bounces interface if stalled"

action_run() {
    local failed_check="$1"

    # Only run for internet/connectivity check failures or manual trigger
    if [ -n "$failed_check" ] && [[ "$failed_check" != *"internet"* && "$failed_check" != *"gateway"* && "$failed_check" != *"manual"* ]]; then
        return 0
    fi

    local con_name
    con_name=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':ethernet|:wifi' | head -n1 | cut -d: -f1)
    [ -z "$con_name" ] && con_name="${DEFAULT_PROFILE:-Profile 1}"

    local dev_name
    dev_name=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | grep -E ':ethernet|:wifi' | head -n1 | cut -d: -f1)
    [ -z "$dev_name" ] && dev_name="${DEFAULT_INTERFACE:-enp2s0}"

    watchdog_log "Attempting reconnection for '$con_name' on '$dev_name'..."

    # Step 1: Profile re-activation
    nmcli connection up "$con_name" >/dev/null 2>&1 || nmcli device connect "$dev_name" >/dev/null 2>&1
    sleep 3
    if checks_pass; then
        watchdog_log "Reconnected successfully via profile activation."
        return 0
    fi

    # Step 2: Soft bounce interface
    watchdog_log "Step 1 failed. Bouncing device '$dev_name'..."
    nmcli device disconnect "$dev_name" >/dev/null 2>&1
    sleep 2
    nmcli device connect "$dev_name" >/dev/null 2>&1 || nmcli connection up "$con_name" >/dev/null 2>&1
    sleep 3
    if checks_pass; then
        watchdog_log "Reconnected successfully after bouncing device."
        return 0
    fi

    # Step 3: Full networking subsystem toggle
    watchdog_log "Step 2 failed. Toggling NetworkManager networking subsystem..."
    nmcli networking off >/dev/null 2>&1
    sleep 2
    nmcli networking on >/dev/null 2>&1
    sleep 4
    if checks_pass; then
        watchdog_log "Reconnected successfully after networking toggle."
        return 0
    fi

    watchdog_log "Reconnection sequence completed without confirmed recovery; will retry next cycle."
    return 1
}
