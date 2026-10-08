#!/usr/bin/env bash
# ==============================================================================
# Custom Health Check Template
# Save in: checks/XX-your-check-name.sh (e.g. 20-vpn.sh)
# ==============================================================================

check_name="My Custom Check"
check_description="Describe what this check tests"

check_run() {
    # Put your test commands here:
    # Return 0 if healthy/passing.
    # Return 1 if failing.

    # Example:
    # ping -c 1 my-internal-server.local >/dev/null 2>&1
    return 0
}
