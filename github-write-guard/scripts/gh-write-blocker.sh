#!/bin/bash
# Hook: PreToolUse
# Description: Block GitHub CLI write operations
# Events: PreToolUse

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract tool name and command
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
COMMAND=$(echo "$INPUT" | jq -r '.toolInput.command // empty')

# Only check Bash tool with gh commands
if [[ "$TOOL_NAME" != "Bash" ]] || [[ ! "$COMMAND" =~ ^gh ]]; then
    # Not a gh command, allow it
    echo "{}"
    exit 0
fi

# Check if guard is enabled in settings
SETTINGS_FILE="${HOME}/.claude/settings.json"
if [[ -f "$SETTINGS_FILE" ]]; then
    GUARD_ENABLED=$(jq -r '.githubWriteGuard.enabled // true' "$SETTINGS_FILE" 2>/dev/null || echo "true")
else
    GUARD_ENABLED="true"
fi

if [[ "$GUARD_ENABLED" != "true" ]]; then
    # Guard disabled, allow all commands
    echo "{}"
    exit 0
fi

# Define write operation patterns
WRITE_METHODS=("POST" "PUT" "PATCH" "DELETE")

WRITE_COMMANDS=(
    "gh repo create"
    "gh repo delete"
    "gh repo fork"
    "gh repo rename"
    "gh repo archive"
    "gh issue create"
    "gh issue edit"
    "gh issue close"
    "gh issue delete"
    "gh issue pin"
    "gh issue unpin"
    "gh issue transfer"
    "gh pr create"
    "gh pr edit"
    "gh pr close"
    "gh pr merge"
    "gh pr reopen"
    "gh pr ready"
    "gh pr comment"
    "gh pr review"
    "gh release create"
    "gh release delete"
    "gh release edit"
    "gh release upload"
    "gh run cancel"
    "gh run rerun"
    "gh workflow enable"
    "gh workflow disable"
    "gh workflow run"
    "gh gist create"
    "gh gist edit"
    "gh gist delete"
    "gh project create"
    "gh project edit"
    "gh project delete"
    "gh project item-add"
    "gh project item-edit"
    "gh project item-delete"
    "gh project field-create"
    "gh project field-delete"
)

# Function to log blocked attempts
log_blocked() {
    local cmd="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check if logging is enabled
    if [[ -f "$SETTINGS_FILE" ]]; then
        LOG_ENABLED=$(jq -r '.githubWriteGuard.logBlockedAttempts // true' "$SETTINGS_FILE" 2>/dev/null || echo "true")
        LOG_PATH=$(jq -r '.githubWriteGuard.logPath // "~/.claude/logs/gh-write-guard.log"' "$SETTINGS_FILE" 2>/dev/null)
        LOG_PATH="${LOG_PATH/#\~/$HOME}"
    else
        LOG_ENABLED="true"
        LOG_PATH="${HOME}/.claude/logs/gh-write-guard.log"
    fi

    if [[ "$LOG_ENABLED" == "true" ]]; then
        mkdir -p "$(dirname "$LOG_PATH")"
        echo "[$timestamp] BLOCKED: $cmd" >> "$LOG_PATH"
    fi
}

# Function to check whitelist
is_whitelisted() {
    local cmd="$1"

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        return 1
    fi

    local allowed_cmds=$(jq -r '.githubWriteGuard.allowedWriteCommands[]? // empty' "$SETTINGS_FILE" 2>/dev/null)

    # If no whitelist entries, return false
    if [[ -z "$allowed_cmds" ]]; then
        return 1
    fi

    while IFS= read -r allowed_cmd; do
        # Skip empty lines
        if [[ -n "$allowed_cmd" ]] && [[ "$cmd" =~ ^$allowed_cmd ]]; then
            return 0
        fi
    done <<< "$allowed_cmds"

    return 1
}

# Function to block command with message
block_command() {
    local cmd_type="$1"
    local suggestion="${2:-}"

    log_blocked "$COMMAND"

    local message="🛡️ **GitHub Write Guard: Command Blocked**\n\n"
    message+="**Command:** \`$cmd_type\`\n\n"
    message+="**Reason:** This is a write operation that modifies GitHub resources.\n\n"
    message+="**Allowed:** Read-only commands (view, list, status, clone, etc.)\n\n"

    if [[ -n "$suggestion" ]]; then
        message+="**Tip:** $suggestion\n\n"
    fi

    message+="**Need to make changes?**\n"
    message+="- Ask the user for explicit permission first\n"
    message+="- Run \`/gh-guard-disable\` to temporarily disable protection\n"
    message+="- Add exception to settings: \`allowedWriteCommands\`"

    cat << EOF
{
  "approved": false,
  "systemMessage": "$message"
}
EOF
}

# Check for gh api with write methods
if [[ "$COMMAND" =~ ^gh[[:space:]]+api ]]; then
    # Check for explicit HTTP methods
    for method in "${WRITE_METHODS[@]}"; do
        if [[ "$COMMAND" =~ -X[[:space:]]+$method ]] || \
           [[ "$COMMAND" =~ --method[[:space:]]+$method ]] || \
           [[ "$COMMAND" =~ --method=$method ]]; then

            if is_whitelisted "$COMMAND"; then
                echo "{}"
                exit 0
            fi

            block_command "gh api $method request" "Use GET for read-only operations: gh api -X GET <endpoint>"
            exit 0
        fi
    done

    # Check for parameter flags that switch to POST (the trap!)
    if [[ "$COMMAND" =~ -[fF][[:space:]] ]] || \
       [[ "$COMMAND" =~ --field ]] || \
       [[ "$COMMAND" =~ --raw-field ]]; then

        # Check if explicitly using GET
        if ! [[ "$COMMAND" =~ -X[[:space:]]+GET ]] && \
           ! [[ "$COMMAND" =~ --method[[:space:]]+GET ]] && \
           ! [[ "$COMMAND" =~ --method=GET ]]; then

            if is_whitelisted "$COMMAND"; then
                echo "{}"
                exit 0
            fi

            block_command "gh api with parameters (defaults to POST)" "Add -X GET to use parameters with GET: gh api -X GET <endpoint> -f param=value"
            exit 0
        fi
    fi

    # If we get here, it's a safe gh api GET command
    echo "{}"
    exit 0
fi

# Check for other write commands
for write_cmd in "${WRITE_COMMANDS[@]}"; do
    if [[ "$COMMAND" =~ ^$write_cmd ]]; then
        if is_whitelisted "$COMMAND"; then
            echo "{}"
            exit 0
        fi

        cmd_name=$(echo "$write_cmd" | sed 's/gh //')
        block_command "gh $cmd_name" "Use 'gh ${cmd_name%% *} view' or 'gh ${cmd_name%% *} list' for read-only access"
        exit 0
    fi
done

# Command is safe (read-only), allow it
echo "{}"
exit 0
