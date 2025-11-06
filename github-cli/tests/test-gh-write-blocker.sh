#!/usr/bin/env bash
# Test Suite for github-cli
# Tests the gh_write_blocker.py hook script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../scripts/gh_write_blocker.py"

print_section "GitHub CLI Security Guard Tests"

# Test 1: Allow non-gh commands
print_section "Test: Allow Non-GH Commands"

run_test "Allow git command" \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow npm command" \
    '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow echo command" \
    '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 2: Allow gh read commands
print_section "Test: Allow GH Read Commands"

run_test "Allow gh repo view" \
    '{"tool_name":"Bash","tool_input":{"command":"gh repo view"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh pr list" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr list"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh issue list" \
    '{"tool_name":"Bash","tool_input":{"command":"gh issue list"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh pr view" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr view 123"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh api GET" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api /repos/owner/repo"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh api explicit GET" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X GET /repos/owner/repo"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 3: Block gh write commands
print_section "Test: Block GH Write Commands"

run_test "Block gh repo create" \
    '{"tool_name":"Bash","tool_input":{"command":"gh repo create my-repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh repo delete" \
    '{"tool_name":"Bash","tool_input":{"command":"gh repo delete owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh pr create" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"Test\""}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh pr merge" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 123"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh pr close" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr close 123"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh issue create" \
    '{"tool_name":"Bash","tool_input":{"command":"gh issue create --title \"Bug\""}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh issue close" \
    '{"tool_name":"Bash","tool_input":{"command":"gh issue close 456"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh release create" \
    '{"tool_name":"Bash","tool_input":{"command":"gh release create v1.0.0"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh workflow run" \
    '{"tool_name":"Bash","tool_input":{"command":"gh workflow run ci.yml"}}' \
    2 \
    "$HOOK_SCRIPT"

# Test 4: Block gh api write operations
print_section "Test: Block GH API Write Operations"

run_test "Block gh api POST" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X POST /repos/owner/repo/issues"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api --method POST" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api --method POST /repos/owner/repo/issues"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api --method=POST" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api --method=POST /repos/owner/repo/issues"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api PUT" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X PUT /repos/owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api DELETE" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X DELETE /repos/owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api PATCH" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X PATCH /repos/owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

# Test 5: Block gh api with field parameters (implicit POST)
print_section "Test: Block GH API Implicit POST"

run_test "Block gh api with -f flag (implicit POST)" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api /repos/owner/repo/issues -f title=test"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api with --field (implicit POST)" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api /repos/owner/repo/issues --field title=test"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api with -F flag (implicit POST)" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api /repos/owner/repo/issues -F title=test"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Allow gh api with -f but explicit GET" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X GET /repos/owner/repo -f param=value"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 6: Handle edge cases
print_section "Test: Edge Cases"

run_test "Handle empty command" \
    '{"tool_name":"Bash","tool_input":{"command":""}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle non-Bash tool" \
    '{"tool_name":"Write","tool_input":{"file_path":"test.txt"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle commands starting with gh (but not gh command)" \
    '{"tool_name":"Bash","tool_input":{"command":"ghost --version"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 7: HTTP Method Case Sensitivity (PHASE 1 - Security Critical)
print_section "Test: Case Sensitivity in HTTP Methods"

run_test "Block gh api with lowercase post" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X post /repos/owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block gh api with mixed case Post" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X Post /repos/owner/repo"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Allow gh api with HEAD method" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X HEAD /repos/owner/repo"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow gh api with OPTIONS method" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api -X OPTIONS /repos/owner/repo"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 8: Complex Command Arguments (PHASE 2 - Robustness)
print_section "Test: Complex Arguments and Quotes"

run_test "Block pr create with 'delete' in title (not confused)" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"Fix: Delete API\""}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block api POST with --input flag" \
    '{"tool_name":"Bash","tool_input":{"command":"gh api /repos/owner/repo --method POST --input -"}}' \
    2 \
    "$HOOK_SCRIPT"

# Test 9: Multiple Write Operations in Chain
print_section "Test: Chained Write Operations"

run_test "Block pr create in command chain" \
    '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title Test && gh pr list"}}' \
    2 \
    "$HOOK_SCRIPT"

run_test "Block issue create with OR fallback" \
    '{"tool_name":"Bash","tool_input":{"command":"gh issue create --title Bug || gh issue list"}}' \
    2 \
    "$HOOK_SCRIPT"

print_section "Test Suite Complete"
