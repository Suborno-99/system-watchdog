#!/usr/bin/env bash
# ==============================================================================
# Check: Internet & Gateway Connectivity
# ==============================================================================

check_name="Internet & Gateway Connectivity"
check_description="Pings DNS/gateway targets and queries NetworkManager connectivity status"

check_run() {
    # 1. Ping targets defined in config or defaults
    for target in "${PING_TARGETS[@]}"; do
        if ping -c 1 -W 2 "$target" >/dev/null 2>&1; then
            return 0
        fi
    done

    # 2. Check NetworkManager status as fallback
    local nm_status
    nm_status=$(nmcli -t -f CONNECTIVITY general status 2>/dev/null || nmcli networking connectivity 2>/dev/null)
    if [ "$nm_status" = "full" ]; then
        return 0
    fi

    return 1
}
