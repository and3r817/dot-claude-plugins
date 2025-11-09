# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Collection of Claude Code plugins providing hooks for enforcing best practices, security, and modern tooling standards.
Each plugin is independently installable and follows a consistent structure.

## Plugin Architecture

**📚 See [docs/plugin-architecture.md](docs/plugin-architecture.md) for comprehensive architecture documentation**

Quick reference:

- **Progressive Disclosure**: Metadata first, core logic on trigger, supporting resources on demand
- **Required**: `.claude-plugin/plugin.json`, `tests/`, `README.md`
- **Optional**: `hooks/`, `scripts/`, `references/`, `assets/`, `commands/`, `skills/`
- **Plugin Types**: Hook (enforcement), Skill (capability), Hybrid (both)

**Hook Implementation Patterns:**

**📚 See [docs/hook-implementation.md](docs/hook-implementation.md) for detailed patterns and examples**

Quick reference:

- Parse JSON from stdin: `{"tool_name": "Bash", "tool_input": {"command": "..."}}`
- Exit 0 (allow) or exit 2 (block)
- Timeout: 1 second
- Use `${CLAUDE_PLUGIN_ROOT}` in hooks.json
- Load references/assets only when needed

## Available Plugins

1. **github-cli** — GitHub CLI companion with security guard + comprehensive usage skill
2. **python-manager-enforcer** — Enforces Poetry/UV/Rye/PDM/etc. in managed projects
3. **native-timeout-enforcer** — Blocks timeout/gtimeout, suggests Bash tool's timeout param
4. **modern-cli-enforcer** — Enforces rg/fd/bat/eza over grep/find/cat/ls
5. **codex-advisor** — Advisory skill for architecture/design consultation

## Testing

**Test Framework:**

- `test-framework.sh` — Core test runner with colored output
- `run-all-tests.sh` — Master runner for all plugin tests
- Individual test suites in `<plugin>/tests/test-*.sh`

**Run Tests:**

```bash
# All plugins
./run-all-tests.sh

# Single plugin
./test-framework.sh github-write-guard/tests/test-gh-write-blocker.sh
```

**Test Function API:**

```bash
run_test "Test name" \
    '{"tool_name":"Bash","tool_input":{"command":"test cmd"}}' \
    <expected_exit_code> \
    "$HOOK_SCRIPT" \
    "<optional_output_pattern>"
```

**Test Requirements:**

- Exit 0 = allow (hook passes)
- Exit 2 = block (hook rejects)
- Test both allow and block cases
- Test edge cases: empty input, invalid JSON, false positives
- Validate helpful error messages with output patterns

See `TESTING.md` for comprehensive testing guide.

## Development Workflow

### Adding a New Plugin

**📚 See [docs/adding-new-plugin.md](docs/adding-new-plugin.md) for comprehensive step-by-step guide**

Quick reference for iterative development process:

**Step 1: Plan Plugin Components**

Identify what the plugin needs based on concrete examples:

- What commands or events should it intercept?
- What validation logic is needed? (→ scripts/)
- What reference data does it need? (→ references/)
- What templates or configs will it use? (→ assets/)
- Does it need user controls? (→ commands/)

**Step 2: Create Plugin Structure**

Create minimal required structure:

```bash
mkdir -p plugin-name/{.claude-plugin,scripts,tests}
touch plugin-name/.claude-plugin/plugin.json
touch plugin-name/README.md
```

Add optional directories only if Step 1 identified a need:

```bash
mkdir -p plugin-name/{references,assets,commands,hooks}
```

**Step 3: Implement Core Components**

In order:

1. Write `plugin.json` with name, description, component paths
2. Implement hook script in `scripts/` (Python preferred)
3. Add hook configuration to `hooks/hooks.json`
4. Create `references/` files if validation needs reference data
5. Create `assets/` files if hooks need templates or configs
6. Add `commands/` if user controls are needed
7. Write `README.md` with installation and usage

**Step 4: Create Test Suite**

1. Create test suite in `tests/test-*.sh`
2. Test positive cases (commands that should pass)
3. Test negative cases (commands that should block)
4. Test edge cases (empty input, invalid JSON, false positives)
5. Validate error messages with output patterns

**Step 5: Integrate and Validate**

1. Add test suite to `run-all-tests.sh` TEST_SUITES array
2. Run tests: `./run-all-tests.sh`
3. Add plugin to `.claude-plugin/marketplace.json`
4. Update root README.md

**Step 6: Iterate**

After testing the plugin in real usage:

1. Notice struggles or inefficiencies
2. Identify improvements (scripts/, references/, assets/, error messages)
3. Update components and re-test
4. Repeat until plugin performs well

**Hook Development:**

- Parse stdin JSON with jq or Python json module
- Extract command: `.tool_input.command`
- Block: `echo "Error message" >&2; exit 2`
- Allow: `exit 0`
- Keep fast (< 1 second)
- Provide helpful suggestions in error messages

**Test Development:**

- Source test framework functions
- Test both positive and negative cases
- Include edge cases (empty, invalid, substring matches)
- Use output patterns to validate error messages
- Print section headers for clarity

## Plugin Manifest Format

**📚 See [docs/plugin-manifest.md](docs/plugin-manifest.md) for complete manifest format reference**

Minimal plugin.json:

```json
{
  "name": "plugin-name",
  "description": "What it does"
}
```

**Note**: hooks/hooks.json is auto-loaded; do not specify in manifest.

## Hook Configuration Format

**📚 See [docs/hook-configuration.md](docs/hook-configuration.md) for complete hook configuration reference**

Basic hooks/hooks.json structure:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/script.py",
            "timeout": 1,
            "description": "What this hook does"
          }
        ]
      }
    ]
  }
}
```

## Marketplace Configuration

**Root marketplace manifest** (`.claude-plugin/marketplace.json`):

- Defines installable plugin collection
- Points to plugin subdirectories with `source` field
- Include description and tags for discovery
- Current owner: `and3r817`

## Commands

```bash
# Testing
./run-all-tests.sh                               # Run all test suites
./test-framework.sh <plugin>/tests/test-*.sh     # Run specific test

# Plugin development
jq . <plugin>/.claude-plugin/plugin.json         # Validate JSON
echo '{"tool_name":"Bash",...}' | python3 script.py  # Test hook manually

# Installation (in Claude Code)
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install <plugin-name>@dot-claude-plugins
/plugin list
```

## Code Quality

**Hook Scripts:**

- Fast execution (< 1 second timeout)
- Parse JSON from stdin
- Write errors to stderr
- Exit 2 to block, 0 to allow
- Provide actionable suggestions in error messages
- Handle edge cases gracefully

**Test Suites:**

- Cover positive cases (commands that should pass)
- Cover negative cases (commands that should be blocked)
- Test edge cases and invalid input
- Validate error message content with patterns
- Use descriptive test names

**Documentation:**

- README.md with installation and usage
- Clear description in plugin.json
- Comment complex hook logic
- Reference TESTING.md for test patterns

## Project-Specific Notes

**Python Hook Scripts:**

- Located in `<plugin>/scripts/`
- Use `#!/usr/bin/env python3` shebang
- Import json, sys for stdin parsing
- Preferred over bash for complex logic

**Test Framework Features:**

- Colored output (green ✓, red ✗)
- Section headers for organization
- Exit code validation
- Optional stderr pattern matching
- Summary with pass/fail counts

**Marketplace Integration:**

- Plugins installable via Claude Code `/plugin` command
- Public marketplace: `and3r817/dot-claude-plugins`
- Local dev workflow supported with relative paths
