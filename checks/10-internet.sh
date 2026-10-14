#!/usr/bin/env bash
# ==============================================================================
# Check: Internet & Gateway Connectivity
# Fully compatible with Arch, Debian, Ubuntu, Fedora, openSUSE, etc.
# ==============================================================================

check_name="Internet & DNS Connectivity (IPv4)"
check_description="Verifies IPv4 web reachability, external WAN pings, and DNS resolution"

check_run() {
    # 1. Quick real-world IPv4 web check (verifies DNS + WAN HTTP, exactly what browser search requires)
    # Using curl -4 ensures we don't stall on broken or misconfigured IPv6 routing/tunnels
    if curl -4 -s --head --request GET --connect-timeout 2 --max-time 3 http://connectivity-check.ubuntu.com >/dev/null 2>&1 \
       || curl -4 -s --head --request GET --connect-timeout 2 --max-time 3 http://www.google.com >/dev/null 2>&1; then
        return 0
    fi

    # 2. Check external IP reachability (external WAN only; do NOT check local router gateway)
    local ip_reachable=false
    local targets=("${PING_TARGETS[@]:-1.1.1.1 8.8.8.8 9.9.9.9}")
    for target in "${targets[@]}"; do
        [ -z "$target" ] && continue
        if ping -4 -c 1 -W 2 "$target" >/dev/null 2>&1 || ping -c 1 -W 2 "$target" >/dev/null 2>&1; then
            ip_reachable=true
            break
        fi
    done

    # 3. Check DNS resolution (essential for browser search, web APIs, and collaboration apps)
    local dns_working=false
    local dns_domains=("${DNS_TARGETS[@]:-google.com cloudflare.com}")
    for domain in "${dns_domains[@]}"; do
        [ -z "$domain" ] && continue
        # Prioritize systemd-resolved via resolvectl query -4
        if command -v resolvectl >/dev/null 2>&1 && resolvectl query -4 "$domain" >/dev/null 2>&1; then
            dns_working=true
            break
        elif getent ahostsv4 "$domain" >/dev/null 2>&1 || host -4 -W 2 "$domain" >/dev/null 2>&1 || host -W 2 "$domain" >/dev/null 2>&1; then
            dns_working=true
            break
        fi
    done

    # Distinguish failure cause for downstream recovery actions
    if [ "$ip_reachable" = true ] && [ "$dns_working" = false ]; then
        LAST_FAILED_CHECK="DNS Resolution Failure (IPv4)"
        return 1
    fi

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

    LAST_FAILED_CHECK="Internet & Gateway Connectivity"
    return 1
}
