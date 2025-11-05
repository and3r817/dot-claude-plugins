#!/usr/bin/env bash
# Test Suite for native-timeout-enforcer
# Tests the validate_timeout.py hook script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../scripts/validate_timeout.py"

print_section "Native Timeout Enforcer Tests"

# Test 1: Allow commands without timeout
print_section "Test: Allow Commands Without Timeout"

run_test "Allow python command" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow npm command" \
    '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow long-running command" \
    '{"tool_name":"Bash","tool_input":{"command":"sleep 10"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 2: Block direct timeout usage
print_section "Test: Block Direct Timeout Usage"

run_test "Block timeout 5 command" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 5 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with seconds" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 10s python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with minutes" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 2m npm test"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block gtimeout (GNU version)" \
    '{"tool_name":"Bash","tool_input":{"command":"gtimeout 5 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with flags" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout --preserve-status 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

# Test 3: Block timeout in command chains
print_section "Test: Block Timeout in Command Chains"

run_test "Block timeout after &&" \
    '{"tool_name":"Bash","tool_input":{"command":"cd /tmp && timeout 5 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout after ||" \
    '{"tool_name":"Bash","tool_input":{"command":"echo start || timeout 5 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout after semicolon" \
    '{"tool_name":"Bash","tool_input":{"command":"echo start; timeout 5 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

# Test 4: Block timeout in pipes
print_section "Test: Block Timeout in Pipes"

run_test "Block timeout in pipe (after |)" \
    '{"tool_name":"Bash","tool_input":{"command":"cat file.txt | timeout 5 grep pattern"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout before pipe" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 5 python script.py | tee output.txt"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

# Test 5: Don't block words containing 'timeout'
print_section "Test: Avoid False Positives"

run_test "Don't block 'set_timeout' function" \
    '{"tool_name":"Bash","tool_input":{"command":"python -c \"set_timeout(5)\""}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Don't block timeout in string" \
    '{"tool_name":"Bash","tool_input":{"command":"echo \"timeout is 5 seconds\""}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 6: Handle edge cases
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

# Test 7: Extended Duration Formats (PHASE 2 - Better Error Messages)
print_section "Test: Hours and Days Duration Format"

run_test "Block timeout with hours (1h)" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 1h python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with days (2d)" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout 2d npm test"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

# Test 8: Additional Timeout Flags
print_section "Test: Timeout with Additional Flags"

run_test "Block timeout with --foreground flag" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout --foreground 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with --kill-after" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout --kill-after=2 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with -k short form" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout -k 2 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

# Test 9: Signal Specifications
print_section "Test: Timeout with Signal Options"

run_test "Block timeout with --signal=TERM" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout --signal=TERM 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

run_test "Block timeout with -s KILL" \
    '{"tool_name":"Bash","tool_input":{"command":"timeout -s KILL 10 python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "BLOCKED"

print_section "Test Suite Complete"
