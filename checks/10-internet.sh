#!/usr/bin/env bash
# ==============================================================================
# Check: Internet & Gateway Connectivity
# Fully compatible with Arch, Debian, Ubuntu, Fedora, openSUSE, etc.
# ==============================================================================

check_name="Internet & Gateway Connectivity"
check_description="Pings DNS/gateway targets and queries NetworkManager or systemd-networkd status"

check_run() {
    # 1. Quick real-world web check (verifies DNS + WAN HTTP, exactly what browser search requires)
    if curl -s --head --request GET --connect-timeout 2 --max-time 3 http://connectivity-check.ubuntu.com >/dev/null 2>&1 \
       || curl -s --head --request GET --connect-timeout 2 --max-time 3 http://www.google.com >/dev/null 2>&1; then
        return 0
    fi

    # 2. Check external IP reachability (external WAN only; do NOT check local router gateway)
    local ip_reachable=false
    local targets=("${PING_TARGETS[@]:-1.1.1.1 8.8.8.8}")
    for target in "${targets[@]}"; do
        [ -z "$target" ] && continue
        if ping -c 1 -W 2 "$target" >/dev/null 2>&1; then
            ip_reachable=true
            break
        fi
    done

    # 3. Check DNS resolution (essential for browser search to function)
    local dns_working=false
    local dns_domains=("${DNS_TARGETS[@]:-google.com cloudflare.com}")
    for domain in "${dns_domains[@]}"; do
        [ -z "$domain" ] && continue
        if getent ahostsv4 "$domain" >/dev/null 2>&1 || getent hosts "$domain" >/dev/null 2>&1 || host -W 2 "$domain" >/dev/null 2>&1; then
            dns_working=true
            break
        fi
    done

    # If external IP is reachable AND DNS works, consider connection healthy
    if [ "$ip_reachable" = true ] && [ "$dns_working" = true ]; then
        return 0
    fi

    # 4. Fallback: Check NetworkManager active connectivity probe (only if DNS also resolves)
    if command -v nmcli >/dev/null 2>&1; then
        local nm_status
        nm_status=$(nmcli networking connectivity check 2>/dev/null || nmcli -t -f CONNECTIVITY general status 2>/dev/null)
        if [ "$nm_status" = "full" ] && [ "$dns_working" = true ]; then
            return 0
        fi
    fi

    return 1
}
