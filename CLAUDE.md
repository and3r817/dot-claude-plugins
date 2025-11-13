# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Claude Code plugin marketplace providing PreToolUse hooks (enforcement), skills (capabilities), and hybrid plugins. Each
plugin is independently installable and follows a progressive disclosure architecture.

## Core Architecture Principles

**Progressive Disclosure**: Load components only when execution requires them (minimize token usage)

- Always loaded: `plugin.json` (metadata only)
- Auto-loaded: `hooks/hooks.json` (event handler definitions)
- On demand: `scripts/` (execution logic), `references/` (decision data), `assets/` (templates)

**Plugin Directory Structure**:

```
plugin-name/
├── .claude-plugin/plugin.json    # Required: metadata
├── hooks/hooks.json               # Optional: PreToolUse event handlers
├── scripts/enforce.py             # Optional: validation logic (Python preferred)
├── tests/test-*.sh                # Required: test suite using test-framework.sh
└── README.md                      # Required: installation/usage
```

**Hook Script Contract** (PreToolUse stdin format):

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "..."
  }
}
```

- Exit 0 = allow | Exit 2 = block | Other = log but allow
- Timeout: 1 second max (keep logic minimal)
- Errors to stderr with actionable suggestions
- Must handle: empty input, invalid JSON, missing fields

**Hook Script Implementation Pattern**:

```python
#!/usr/bin/env python3
import json, sys

try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '')

    if not cmd:
        sys.exit(0)

    # Validation logic here
    if should_block:
        sys.stderr.write("Error message with suggestion")
        sys.exit(2)

    sys.exit(0)
except Exception:
    sys.exit(0)  # Always fail gracefully
```

## Testing Commands

```bash
# Run all test suites (master runner)
./run-all-tests.sh

# Run specific plugin tests
./test-framework.sh <plugin>/tests/test-*.sh

# Manual hook testing
echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' | python3 <plugin>/scripts/script.py
echo "Exit code: $?"
```

**Test Framework API** (`test-framework.sh` provides these functions):

```bash
run_test "Test name" \
    '{"tool_name":"Bash","tool_input":{"command":"..."}}'  # stdin JSON
    0 \                                                     # expected exit code
    "$HOOK_SCRIPT" \                                       # script path
    "error pattern"                                        # optional stderr regex

print_section "Section Title"  # Test organization
print_summary                  # Exit with test results
```

**Test Requirements**:

- Positive cases (should allow), negative cases (should block), edge cases (empty/invalid JSON)
- Validate error messages with output patterns
- Add new test suites to `run-all-tests.sh` TEST_SUITES array

## Plugin Development Workflow

**New Plugin Checklist**:

1. Create structure: `mkdir -p plugin/{.claude-plugin,scripts,tests,hooks}`
2. Write `plugin.json` (name, description)
3. Implement hook script in `scripts/` (Python preferred for complex logic)
4. Configure `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}/scripts/script.py`
5. Create test suite in `tests/test-*.sh` (positive/negative/edge cases)
6. Add to `run-all-tests.sh` TEST_SUITES array
7. Run `./run-all-tests.sh` to validate
8. Add plugin entry to `.claude-plugin/marketplace.json`
9. Update root `README.md`

**Validation Commands**:

```bash
jq . <plugin>/.claude-plugin/plugin.json  # Validate manifest JSON
./test-framework.sh <plugin>/tests/test-*.sh  # Test individual suite
```

## Command Detection Pattern (Avoid False Positives)

Hook scripts must detect commands as execution tokens, not substrings in arguments/paths:

```python
def has_command_word(cmd: str, word: str) -> bool:
    """Check if word appears as command (not argument/path)"""
    # Split by shell operators: |, &&, ||, ;
    for delimiter in ['|', '&&', '||', ';']:
        cmd = cmd.replace(delimiter, '\n')

    # Check first token of each segment
    for segment in cmd.split('\n'):
        tokens = segment.strip().split()
        if tokens and tokens[0] == word:
            return True
    return False
```

This prevents blocking `grep` in `cat mygrep.txt` or `find` in `/path/to/find/file`.

## Marketplace Integration

**Add marketplace** (Claude Code):

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install <plugin-name>@dot-claude-plugins
/plugin list
```

**Marketplace configuration** (`.claude-plugin/marketplace.json`):

- Owner: `and3r817`
- Each plugin entry requires: `name`, `source` (relative path), `description`, `tags`

## Available Plugins

- **github-cli**: Security guard (blocks gh write ops) + comprehensive gh usage skill
- **modern-cli-enforcer**: Enforces rg/fd/bat/eza over grep/find/cat/ls
- **native-timeout-enforcer**: Blocks timeout/gtimeout, suggests Bash tool's native timeout param
- **python-manager-enforcer**: Enforces Poetry/UV/Rye/PDM in managed projects
- **codex-advisor**: Advisory skill for architecture/design consultation (no code changes)

## Documentation References

- **[docs/plugin-architecture.md](docs/plugin-architecture.md)**: Progressive disclosure model, component purposes
- **[docs/adding-new-plugin.md](docs/adding-new-plugin.md)**: Step-by-step plugin creation guide
- **[docs/plugin-manifest.md](docs/plugin-manifest.md)**: plugin.json format reference
- **[docs/hook-configuration.md](docs/hook-configuration.md)**: hooks.json format reference
- **[TESTING.md](TESTING.md)**: Comprehensive testing guide with examples

## Project Conventions

**Python Hook Scripts**:

- Shebang: `#!/usr/bin/env python3`
- Minimal imports: `json`, `sys`, `shutil` (for command availability checks)
- Always gracefully handle exceptions (exit 0 on errors)
- Write actionable suggestions to stderr before exit 2

**Test Organization**:

- Group by category with `print_section` headers
- Descriptive test names: "Block grep when rg available" (not "Test 1")
- Extend existing test files (don't create new ones per memory `hook-test-edge-cases-design`)
- Test security-critical cases first (e.g., HTTP method case sensitivity for gh hooks)

**Serena MCP Usage**:

- Memory: `hook-test-edge-cases-design` (test patterns and edge case documentation)
- Use symbolic tools (`find_symbol`, `get_symbols_overview`) over full file reads
