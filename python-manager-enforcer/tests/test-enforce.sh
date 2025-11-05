#!/usr/bin/env bash
# Test Suite for python-manager-enforcer
# Tests the enforce.py hook script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../scripts/enforce.py"

print_section "Python Manager Enforcer Tests"

# Test 1: Allow non-python commands
print_section "Test: Allow Non-Python Commands"

run_test "Allow npm command" \
    '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow bash command" \
    '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow git command" \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 2: Allow python bootstrapping commands
print_section "Test: Allow Python Bootstrapping"

run_test "Allow python -m poetry" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 -m poetry install"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow python -m uv" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 -m uv sync"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow python -m pip" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 -m pip install package"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow python -m venv" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 -m venv .venv"}}' \
    0 \
    "$HOOK_SCRIPT"

# Test 3: Block direct python when no manager detected (requires temp directory)
print_section "Test: Allow Python Without Manager"

# Create temp directory without package manager files
TEMP_DIR=$(mktemp -d)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Allow python when no manager detected" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Allow python3 when no manager detected" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 script.py"}}' \
    0 \
    "$HOOK_SCRIPT"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 4: Block python in Poetry project
print_section "Test: Block Python in Poetry Project"

# Create temp directory with poetry.lock
TEMP_DIR=$(mktemp -d)
touch "$TEMP_DIR/poetry.lock"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Block python in Poetry project" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "poetry"

run_test "Block python3 in Poetry project" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "poetry"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 5: Block python in UV project
print_section "Test: Block Python in UV Project"

# Create temp directory with uv.lock
TEMP_DIR=$(mktemp -d)
touch "$TEMP_DIR/uv.lock"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Block python in UV project" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "uv"

run_test "Block python3 with args in UV project" \
    '{"tool_name":"Bash","tool_input":{"command":"python3 -u script.py --arg value"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "uv"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 6: Handle edge cases
print_section "Test: Edge Cases"

run_test "Handle empty command" \
    '{"tool_name":"Bash","tool_input":{"command":""}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle missing command field" \
    '{"tool_name":"Bash","input":{}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Handle invalid JSON (should exit 0 for safety)" \
    'invalid json' \
    0 \
    "$HOOK_SCRIPT"

# Test 7: Don't block commands containing 'python'
print_section "Test: Avoid False Positives"

TEMP_DIR=$(mktemp -d)
touch "$TEMP_DIR/poetry.lock"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Don't block commands with 'python' in name" \
    '{"tool_name":"Bash","tool_input":{"command":"mypython_script.sh"}}' \
    0 \
    "$HOOK_SCRIPT"

run_test "Don't block echo with python text" \
    '{"tool_name":"Bash","tool_input":{"command":"echo \"python version\""}}' \
    0 \
    "$HOOK_SCRIPT"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 8: Test documented format (.tool_input)
print_section "Test: Documented Input Format"

TEMP_DIR=$(mktemp -d)
touch "$TEMP_DIR/pyproject.toml"
echo "[tool.poetry]" > "$TEMP_DIR/pyproject.toml"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Block with .tool_input format" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "poetry"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 9: Multiple Manager Conflict Detection (PHASE 1 - Prevents Incorrect Suggestions)
print_section "Test: Multiple Package Managers (Conflict)"

# Create temp directory with BOTH Poetry and UV lock files
TEMP_DIR=$(mktemp -d)
touch "$TEMP_DIR/poetry.lock"
touch "$TEMP_DIR/uv.lock"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Poetry wins when both poetry.lock and uv.lock exist" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "poetry"

# Clean up
rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 10: pyproject.toml with Multiple Tool Sections
print_section "Test: pyproject.toml with Multiple Managers"

TEMP_DIR=$(mktemp -d)
cat > "$TEMP_DIR/pyproject.toml" <<'EOF'
[tool.poetry]
name = "test"

[tool.pdm]
name = "test"
EOF
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Poetry wins in pyproject.toml with multiple [tool.*]" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "poetry"

rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

# Test 11: .python-version Detection (PHASE 2 - Rye/UV users)
print_section "Test: .python-version Detection"

# .python-version without rye markers (should detect as UV)
TEMP_DIR=$(mktemp -d)
echo "3.11.0" > "$TEMP_DIR/.python-version"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Detect UV with .python-version (no rye markers)" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "uv"

rm -rf "$TEMP_DIR"

# .python-version with "rye" in content
TEMP_DIR=$(mktemp -d)
echo "3.11.0+rye" > "$TEMP_DIR/.python-version"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Detect Rye with .python-version containing 'rye'" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "rye"

rm -rf "$TEMP_DIR"

# .python-version with .rye directory
TEMP_DIR=$(mktemp -d)
echo "3.11.0" > "$TEMP_DIR/.python-version"
mkdir "$TEMP_DIR/.rye"
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

run_test "Detect Rye with .python-version and .rye directory" \
    '{"tool_name":"Bash","tool_input":{"command":"python script.py"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "rye"

rm -rf "$TEMP_DIR"
unset CLAUDE_PROJECT_DIR

print_section "Test Suite Complete"
