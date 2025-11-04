#!/usr/bin/env bash
# Modern CLI Tool Enforcer Hook
# Detects legacy commands and suggests modern alternatives
# Event: PreToolUse (validates before Bash execution)

set -euo pipefail

# Read command from stdin using proven pattern (with error handling for invalid JSON)
cmd=$(jq -r '.tool_input.command // .input.command // ""' 2>/dev/null || echo "")

# If no command, allow execution
if [ -z "$cmd" ]; then
  exit 0
fi

# Check which modern tools are available
has_rg=$(command -v rg &>/dev/null && echo "true" || echo "false")
has_fd=$(command -v fd &>/dev/null && echo "true" || echo "false")
has_bat=$(command -v bat &>/dev/null && echo "true" || echo "false")
has_eza=$(command -v eza &>/dev/null && echo "true" || echo "false")

# Detect all legacy commands that have modern alternatives available
declare -a blocked_tools=()
declare -a modern_tools=()
declare -a examples=()

# Check for grep when rg is available (highest priority - most common)
if [ "$has_rg" = "true" ] && echo "$cmd" | grep -Eq '\bgrep\b'; then
  blocked_tools+=("grep")
  modern_tools+=("ripgrep (rg)")
  examples+=("grep 'pattern' → rg 'pattern'")
fi

# Check for find when fd is available
if [ "$has_fd" = "true" ] && echo "$cmd" | grep -Eq '\bfind\b'; then
  blocked_tools+=("find")
  modern_tools+=("fd")
  examples+=("find . -name '*.txt' → fd '*.txt'")
fi

# Check for cat when bat is available
if [ "$has_bat" = "true" ] && echo "$cmd" | grep -Eq '\bcat\b'; then
  blocked_tools+=("cat")
  modern_tools+=("bat")
  examples+=("cat file.py → bat file.py")
fi

# Check for ls when eza is available
if [ "$has_eza" = "true" ] && echo "$cmd" | grep -Eq '\bls\b'; then
  blocked_tools+=("ls")
  modern_tools+=("eza")
  examples+=("ls -la → eza -la")
fi

# If any legacy commands detected with modern alternatives, block it
if [ ${#blocked_tools[@]} -gt 0 ]; then
  echo "⚠️  Legacy CLI tool(s) detected. Modern alternatives are available:" >&2
  echo "" >&2
  for i in "${!blocked_tools[@]}"; do
    echo "  • Use ${modern_tools[$i]} instead of ${blocked_tools[$i]}" >&2
  done
  echo "" >&2
  echo "**Why modern tools?**" >&2
  echo "  - Faster performance (parallel processing)" >&2
  echo "  - Better defaults (smart ignore patterns)" >&2
  echo "  - Improved UX (colors, formatting)" >&2
  echo "" >&2
  echo "**Example replacements:**" >&2
  for example in "${examples[@]}"; do
    echo "  ${example}" >&2
  done
  echo "" >&2
  echo "This command will be **blocked**. Please use modern alternatives." >&2
  exit 2
fi

# No legacy commands detected or no modern alternatives available
exit 0
