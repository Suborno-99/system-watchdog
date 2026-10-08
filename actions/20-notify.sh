#!/usr/bin/env bash
# ==============================================================================
# Action: Desktop Notification
# ==============================================================================

action_name="Desktop Notification"
action_description="Sends Cinnamon desktop notifications on recovery"

action_run() {
    local failed_check="$1"
    local status="${2:-recovered}"

    if [ "$NOTIFY_ON_RECOVERY" != "true" ]; then
        return 0
    fi

    if command -v notify-send >/dev/null 2>&1; then
        if [ "$status" = "recovered" ]; then
            notify-send -u normal -i network-transmit-receive "System Watchdog" "Connectivity restored successfully." 2>/dev/null || true
        elif [ "$status" = "failed" ] && [ "$NOTIFY_ON_FAILURE" = "true" ]; then
            notify-send -u critical -i network-error "System Watchdog" "Health check failed: $failed_check" 2>/dev/null || true
        fi
    fi
    return 0
}
