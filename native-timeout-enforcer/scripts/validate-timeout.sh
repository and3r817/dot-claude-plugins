#!/bin/bash
# Native timeout enforcer validation script
# Blocks bash commands using timeout/gtimeout and suggests native timeout parameter

set -e

# Extract command from PreToolUse event
COMMAND="$COMMAND"

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Detection patterns for timeout/gtimeout usage
# Pattern 1: Direct timeout/gtimeout at start
if echo "$COMMAND" | grep -qE "^\s*(timeout|gtimeout)\s+"; then
  # Extract the timeout duration and actual command
  DURATION=$(echo "$COMMAND" | sed -E "s/^\s*(timeout|gtimeout)\s+(--[^\s]+\s+)*([0-9]+[smhd]?)\s+.*/\3/")
  ACTUAL_CMD=$(echo "$COMMAND" | sed -E "s/^\s*(timeout|gtimeout)\s+(--[^\s]+\s+)*[0-9]+[smhd]?\s+//")
  
  # Convert duration to milliseconds for suggestion
  MS_DURATION="5000"
  if [[ "$DURATION" =~ ^[0-9]+s$ ]]; then
    NUM=$(echo "$DURATION" | sed "s/s$//")
    MS_DURATION=$((NUM * 1000))
  elif [[ "$DURATION" =~ ^[0-9]+m$ ]]; then
    NUM=$(echo "$DURATION" | sed "s/m$//")
    MS_DURATION=$((NUM * 60000))
  elif [[ "$DURATION" =~ ^[0-9]+$ ]]; then
    MS_DURATION=$((DURATION * 1000))
  fi
  
  echo "" >&2
  echo "BLOCKED: Direct timeout usage detected" >&2
  echo "" >&2
  echo "Your command: $COMMAND" >&2
  echo "Reason: Use Bash tool native timeout parameter instead" >&2
  echo "" >&2
  echo "Correct usage:" >&2
  echo "   Bash tool with command=$ACTUAL_CMD and timeout=$MS_DURATION" >&2
  echo "" >&2
  echo "Note: timeout values are in milliseconds (5s = 5000ms)" >&2
  echo "" >&2
  exit 1
fi

# Pattern 2: timeout/gtimeout in command chains (&&, ||, ;)
if echo "$COMMAND" | grep -qE "(&&|\|\||;)\s*(timeout|gtimeout)\s+"; then
  echo "" >&2
  echo "BLOCKED: timeout in command chain detected" >&2
  echo "" >&2
  echo "Your command: $COMMAND" >&2
  echo "Reason: Use Bash tool native timeout parameter instead" >&2
  echo "" >&2
  echo "Correct approach:" >&2
  echo "   1. Split commands into separate Bash tool calls" >&2
  echo "   2. Use timeout parameter on the Bash call that needs it" >&2
  echo "   Example: Bash tool with timeout=5000" >&2
  echo "" >&2
  exit 1
fi

# Pattern 3: timeout/gtimeout in pipes
if echo "$COMMAND" | grep -qE "\|\s*(timeout|gtimeout)\s+|^(timeout|gtimeout)\s+[^|]+\|"; then
  echo "" >&2
  echo "BLOCKED: timeout in pipe detected" >&2
  echo "" >&2
  echo "Your command: $COMMAND" >&2
  echo "Reason: Use Bash tool native timeout parameter instead" >&2
  echo "" >&2
  echo "Correct approach:" >&2
  echo "   Apply timeout parameter to the entire Bash tool call" >&2
  echo "   Example: Bash tool with timeout=5000" >&2
  echo "" >&2
  exit 1
fi

# All checks passed
exit 0
