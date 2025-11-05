#!/usr/bin/env bash
# Test Suite for modern-cli-enforcer
# Tests the enforce.py hook script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../scripts/enforce.py"

print_section "Modern CLI Enforcer Tests"

# Helper to check if modern tools are available
HAS_RG=$(command -v rg &>/dev/null && echo "true" || echo "false")
HAS_FD=$(command -v fd &>/dev/null && echo "true" || echo "false")
HAS_BAT=$(command -v bat &>/dev/null && echo "true" || echo "false")
HAS_EZA=$(command -v eza &>/dev/null && echo "true" || echo "false")

print_info "Modern tools available: rg=$HAS_RG fd=$HAS_FD bat=$HAS_BAT eza=$HAS_EZA"

# Test 1: Allow non-legacy commands
print_section "Test: Allow Non-Legacy Commands"

run_test "Allow echo command" \
    '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow cd command" \
    '{"tool_name":"Bash","tool_input":{"command":"cd /tmp"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow npm command" \
    '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 2: Block grep if rg available
if [ "$HAS_RG" = "true" ]; then
    print_section "Test: Block grep (rg available)"

    run_test "Block grep command" \
        '{"tool_name":"Bash","tool_input":{"command":"grep pattern file.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "ripgrep"

    run_test "Block grep with flags" \
        '{"tool_name":"Bash","tool_input":{"command":"grep -r pattern dir/"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "ripgrep"

    run_test "Block grep in pipe" \
        '{"tool_name":"Bash","tool_input":{"command":"cat file.txt | grep pattern"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "ripgrep"
else
    print_info "Skipping grep tests (rg not installed)"
fi

# Test 3: Block find if fd available
if [ "$HAS_FD" = "true" ]; then
    print_section "Test: Block find (fd available)"

    run_test "Block find command" \
        '{"tool_name":"Bash","tool_input":{"command":"find . -name *.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "fd"

    run_test "Block find with type" \
        '{"tool_name":"Bash","tool_input":{"command":"find . -type f"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "fd"
else
    print_info "Skipping find tests (fd not installed)"
fi

# Test 4: Block cat if bat available
if [ "$HAS_BAT" = "true" ]; then
    print_section "Test: Block cat (bat available)"

    run_test "Block cat command" \
        '{"tool_name":"Bash","tool_input":{"command":"cat README.md"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "bat"

    run_test "Block cat with flags" \
        '{"tool_name":"Bash","tool_input":{"command":"cat -n file.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "bat"
else
    print_info "Skipping cat tests (bat not installed)"
fi

# Test 5: Block ls if eza available
if [ "$HAS_EZA" = "true" ]; then
    print_section "Test: Block ls (eza available)"

    run_test "Block ls command" \
        '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "eza"

    run_test "Block ls with path" \
        '{"tool_name":"Bash","tool_input":{"command":"ls /tmp"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "eza"
else
    print_info "Skipping ls tests (eza not installed)"
fi

# Test 6: Don't block substrings
print_section "Test: Avoid False Positives"

run_test "Don't block 'agrep' (contains grep)" \
    '{"tool_name":"Bash","tool_input":{"command":"agrep pattern file.txt"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Don't block 'find_files' (contains find)" \
    '{"tool_name":"Bash","tool_input":{"command":"find_files *.txt"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 7: Handle command chains
if [ "$HAS_RG" = "true" ] && [ "$HAS_FD" = "true" ]; then
    print_section "Test: Command Chains"

    run_test "Block grep in command chain" \
        '{"tool_name":"Bash","tool_input":{"command":"cd /tmp && grep pattern file.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "ripgrep"

    run_test "Block find after semicolon" \
        '{"tool_name":"Bash","tool_input":{"command":"echo start; find . -name *.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "fd"
fi

# Test 8: Handle empty/invalid input
print_section "Test: Edge Cases"

run_test "Handle empty command" \
    '{"tool_name":"Bash","tool_input":{"command":""}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle missing command field" \
    '{"tool_name":"Bash","tool_input":{}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle invalid JSON (should exit 0 for safety)" \
    'invalid json' \
    0 \
    "$HOOK_SCRIPT"

# Test 9: Multiple Legacy Tools (PHASE 1 - Common Real-World Scenario)
print_section "Test: Multiple Legacy Tools in Command"

if [ "$HAS_RG" = "true" ] && [ "$HAS_BAT" = "true" ]; then
    run_test "Block first legacy tool in pipeline" \
        '{"tool_name":"Bash","tool_input":{"command":"grep pattern file.txt | cat"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "ripgrep"
fi

if [ "$HAS_FD" = "true" ] && [ "$HAS_RG" = "true" ]; then
    run_test "Block grep in find+grep combo" \
        '{"tool_name":"Bash","tool_input":{"command":"find . -name *.txt | grep test"}}' \
        2 \
        "$HOOK_SCRIPT"
fi

if [ "$HAS_RG" = "true" ] && [ "$HAS_EZA" = "true" ]; then
    run_test "Block multiple legacy tools in chain" \
        '{"tool_name":"Bash","tool_input":{"command":"ls -la && grep pattern file.txt"}}' \
        2 \
        "$HOOK_SCRIPT"
fi

# Test 10: Tool Names in Strings/Paths (False Positive Prevention)
print_section "Test: Tool Names in Strings and Paths"

run_test "Don't block tool name in echo string" \
    '{"tool_name":"Bash","tool_input":{"command":"echo \"use grep command\""}}' \
    0 \
    "$HOOK_SCRIPT"

if [ "$HAS_BAT" = "true" ]; then
    run_test "Block cat with path containing 'grep'" \
        '{"tool_name":"Bash","tool_input":{"command":"cat /path/to/grep/file.txt"}}' \
        2 \
        "$HOOK_SCRIPT" \
        "bat"
fi

run_test "Don't block script named 'find_files.py'" \
    '{"tool_name":"Bash","tool_input":{"command":"python find_files.py"}}' \
    0 \
    "$HOOK_SCRIPT"

print_section "Test Suite Complete"
