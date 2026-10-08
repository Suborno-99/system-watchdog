#!/usr/bin/env bash
# ==============================================================================
# Custom Recovery Action Template
# Save in: actions/XX-your-action-name.sh (e.g. 30-restart-service.sh)
# ==============================================================================

action_name="My Custom Action"
action_description="Describe what this recovery action does"

action_run() {
    local failed_check="$1"  # Name of check that failed (or "manual")

    watchdog_log "Running action '$action_name' for check '$failed_check'..."

    # Put your recovery / reaction commands here:
    # Return 0 on success, 1 on failure.

    return 0
}
