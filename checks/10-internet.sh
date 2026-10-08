#!/usr/bin/env bash
# ==============================================================================
# Check: Internet & Gateway Connectivity
# Fully compatible with Arch, Debian, Ubuntu, Fedora, openSUSE, etc.
# ==============================================================================

check_name="Internet & Gateway Connectivity"
check_description="Pings DNS/gateway targets and queries NetworkManager or systemd-networkd status"

check_run() {
    # 1. Dynamically discover default gateway
    local gateway
    gateway=$(ip route show default 2>/dev/null | awk '{print $3}' | head -n1)

    # 2. Combine configured targets with auto-detected gateway
    local targets=("${PING_TARGETS[@]}")
    [ -n "$gateway" ] && targets+=("$gateway")

    for target in "${targets[@]}"; do
        [ -z "$target" ] && continue
        if ping -c 1 -W 2 "$target" >/dev/null 2>&1; then
            return 0
        fi
    done

    # 3. Check NetworkManager status if available
    if command -v nmcli >/dev/null 2>&1; then
        local nm_status
        nm_status=$(nmcli -t -f CONNECTIVITY general status 2>/dev/null || nmcli networking connectivity 2>/dev/null)
        if [ "$nm_status" = "full" ]; then
            return 0
        fi
    fi

    # 4. Check systemd-networkd status if available (common on minimal Arch setups)
    if command -v networkctl >/dev/null 2>&1; then
        if networkctl status 2>/dev/null | grep -qi "routable"; then
            return 0
        fi
    fi

    return 1
}
