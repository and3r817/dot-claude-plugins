# Hook Implementation Patterns

**Agent Context**: Read when implementing hooks. Reference for validation patterns and agent constraints.

## When to Consult This Document

**READ when:**

- Implementing new hook script
- Debugging hook validation logic
- Choosing validation pattern (prefix blocking, regex, alternatives)
- Understanding error message formatting

**SKIP when:**

- You already know the validation pattern needed
- Working on non-hook components (skills, tests)

## Hook Execution Model

**Event Flow:**

```
User initiates tool → Claude Code intercepts (PreToolUse)
                   → Hook receives JSON via stdin
                   → Script validates command
                   → Script exits 0 (allow) or 2 (block)
                   → Claude Code proceeds or shows error
```

**Agent Constraints:**

- Timeout: 1 second maximum execution
- Input: JSON from stdin, NOT command-line args
- Output: Exit code 0/2, errors to stderr
- Failure mode: Fail-open (exit 0 on exception for safety)

**WHY 1 second timeout**: Hooks execute synchronously before every tool use. Slow hooks degrade agent responsiveness.

**WHY fail-open**: Hook bugs must not block all tool execution. Better to allow one command than deadlock the agent.

## Core Implementation Pattern

**Minimal hook script structure:**

```python
#!/usr/bin/env python3
import json
import sys

def main():
    try:
        # 1. Parse stdin JSON
        data = json.load(sys.stdin)
        tool = data.get('tool_name', '')
        cmd = data.get('tool_input', {}).get('command', '')

        # 2. Early exit for non-target tools
        if tool != 'Bash':
            sys.exit(0)

        # 3. Simple validation first
        if 'forbidden_pattern' in cmd:
            sys.stderr.write("❌ Error: Forbidden pattern detected\n")
            sys.stderr.write("💡 Suggestion: Use alternative command\n")
            sys.exit(2)

        # 4. Allow by default
        sys.exit(0)

    except Exception:
        # 5. Fail-open on error
        sys.exit(0)

if __name__ == "__main__":
    main()
```

**Agent Implementation Workflow:**

1. Copy minimal pattern above
2. Replace `tool != 'Bash'` with target tool matcher
3. Replace `'forbidden_pattern'` with actual validation logic
4. Add error message with suggestion
5. Test with positive/negative cases

**Corresponding hooks.json:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validator.py",
            "timeout": 1,
            "description": "Validate commands before execution"
          }
        ]
      }
    ]
  }
}
```

**REQUIRED**: Use `${CLAUDE_PLUGIN_ROOT}` for script paths (Claude Code expands at runtime).

## Progressive Disclosure: References Pattern

**When to use:** Validation logic requires >50 patterns or external data

**WHY separate references/**:

- Faster script parsing (200 lines vs 2000 lines)
- Update patterns without modifying code
- Load only when validation path requires

**Implementation with lazy loading:**

```python
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

def load_patterns(ref_file):
    """Load patterns from reference file (called only when needed)."""
    patterns = []
    with open(ref_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                patterns.append(line)
    return patterns

def main():
    try:
        data = json.load(sys.stdin)
        tool = data.get('tool_name', '')
        command = data.get('tool_input', {}).get('command', '')

        if tool != 'Bash':
            sys.exit(0)

        # Simple check first (fast path)
        if not needs_complex_validation(command):
            sys.exit(0)

        # Load references only if complex validation needed (slow path)
        plugin_root = Path(__file__).parent.parent
        ref_file = plugin_root / "references" / "forbidden-patterns.txt"

        if ref_file.exists():
            patterns = load_patterns(ref_file)
            if violates_patterns(command, patterns):
                sys.stderr.write("❌ Error: Command violates pattern rules\n")
                sys.stderr.write("💡 See references/forbidden-patterns.txt\n")
                sys.exit(2)

        sys.exit(0)

    except Exception:
        sys.exit(0)

if __name__ == "__main__":
    main()
```

**Agent Investigation Pattern:**

1. Read script to understand validation flow
2. Identify `load_patterns()` or similar reference loading
3. Note lazy loading pattern (conditional loading)
4. Read references/ ONLY if validation logic requires

**Reference file format** (`references/forbidden-patterns.txt`):

```
# Comments start with #
rm -rf /
sudo rm
format c:
```

**Benefits for Agent:**

- Faster script reads (logic only, not data)
- Clear separation: modify patterns without re-reading script
- Update references without changing tests

## Progressive Disclosure: Assets Pattern

**When to use:** Error messages use templates or configuration suggestions

**WHY separate assets/**:

- Centralized error messages
- Loaded only when generating output (not during validation)
- Template reuse across multiple scripts

**Implementation:**

```python
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

def main():
    try:
        data = json.load(sys.stdin)
        tool = data.get('tool_name', '')
        cmd = data.get('tool_input', {}).get('command', '')

        if tool != 'Bash':
            sys.exit(0)

        # Validation logic (fast)
        if cmd.startswith('dangerous-command'):
            # Load assets only when generating error output
            plugin_root = Path(__file__).parent.parent
            template_file = plugin_root / "assets" / "suggestions.json"

            if template_file.exists():
                suggestions = json.loads(template_file.read_text())
                error = suggestions.get('dangerous-command', {})
                sys.stderr.write(f"❌ {error.get('message')}\n")
                sys.stderr.write(f"💡 {error.get('suggestion')}\n")
            else:
                sys.stderr.write("❌ Dangerous command blocked\n")

            sys.exit(2)

        sys.exit(0)

    except Exception:
        sys.exit(0)

if __name__ == "__main__":
    main()
```

**Asset file format** (`assets/suggestions.json`):

```json
{
  "dangerous-command": {
    "message": "This command is dangerous and blocked",
    "suggestion": "Use safe-alternative instead: safe-command --flag"
  }
}
```

**Agent Workflow:**

- Load assets/ only in error generation path
- Assume assets/ contains templates, NOT validation logic
- Fallback to hardcoded message if asset missing

## Validation Patterns Library

### Pattern: Command Prefix Blocking

**Use when:** Blocking commands by exact prefix match

```python
FORBIDDEN_PREFIXES = ['rm -rf /', 'sudo rm', 'format']

for prefix in FORBIDDEN_PREFIXES:
    if cmd.startswith(prefix):
        sys.stderr.write(f"❌ Blocked: {prefix}\n")
        sys.exit(2)
```

**Performance:** O(n) where n = prefix count (fast for <100 patterns)

### Pattern: Regex Matching

**Use when:** Complex pattern validation (word boundaries, wildcards)

```python
import re

FORBIDDEN_PATTERNS = [
    r'rm\s+-rf\s+/',
    r'sudo\s+rm',
    r':\(\)\{\s*:\|:&\s*\};:'  # Fork bomb
]

for pattern in FORBIDDEN_PATTERNS:
    if re.search(pattern, cmd):
        sys.stderr.write(f"❌ Dangerous pattern detected\n")
        sys.exit(2)
```

**Performance:** O(n*m) where n = pattern count, m = command length (slower, use sparingly)

### Pattern: Alternative Suggestion

**Use when:** Enforcing modern tool alternatives

```python
ALTERNATIVES = {
    'grep': 'rg (ripgrep)',
    'find': 'fd',
    'cat': 'bat',
    'ls': 'eza'
}

for old_cmd, new_cmd in ALTERNATIVES.items():
    if cmd.startswith(old_cmd):
        sys.stderr.write(f"❌ Legacy tool '{old_cmd}' blocked\n")
        sys.stderr.write(f"💡 Use '{new_cmd}' instead\n")
        sys.exit(2)
```

**Agent Modification:** When user requests new alternative, add to ALTERNATIVES dict

### Pattern: Conditional Validation

**Use when:** Context-dependent validation (directory, environment)

```python
# Only validate in specific directories
cwd = data.get('tool_input', {}).get('cwd', '')
if '/production/' in cwd and 'deploy' in cmd:
    sys.stderr.write("❌ Direct deployment blocked in production\n")
    sys.stderr.write("💡 Use /deploy-script instead\n")
    sys.exit(2)
```

**Extract context from:**

- `tool_input.cwd` — Current working directory
- Environment variables (if passed)
- Command content

### Pattern: Multi-Tool Validation

**Use when:** Single script validates multiple tools

```python
if tool == 'Bash':
    # Bash-specific validation
    if 'rm -rf' in cmd:
        sys.stderr.write("❌ Dangerous rm command\n")
        sys.exit(2)
elif tool == 'Write':
    # Write-specific validation
    file_path = data.get('tool_input', {}).get('file_path', '')
    if file_path.endswith('.env'):
        sys.stderr.write("⚠️ Warning: Modifying .env file\n")
        # Allow but warn (exit 0)
elif tool == 'Edit':
    # Edit-specific validation
    old_string = data.get('tool_input', {}).get('old_string', '')
    if 'SECRET_KEY' in old_string:
        sys.stderr.write("❌ Modifying secret key blocked\n")
        sys.exit(2)
```

**hooks.json matcher:** Use `"matcher": "*"` for all tools or list specific tools

## Error Message Format

**Agent Requirements:**

- MUST be actionable (tell user what to do)
- MUST use structured format (emoji + message + suggestion)
- MUST be concise (2-3 lines maximum)

**Standard Format:**

```python
def format_error(cmd, reason, suggestion):
    """Standard error message format."""
    return f"""❌ Command blocked: {cmd}
Reason: {reason}
💡 Suggestion: {suggestion}
"""

sys.stderr.write(format_error(
    cmd="grep pattern file.txt",
    reason="Legacy tool detected",
    suggestion="Use 'rg pattern file.txt' instead"
))
```

**Emoji Convention:**

- ❌ — Error/blocked (MUST use for blocks)
- 💡 — Suggestion/alternative (MUST provide actionable suggestion)
- ⚠️ — Warning (allow but notify)
- ✅ — Success/allowed (rarely needed)
- 🔍 — Detection/analysis

**Good Error Messages:**

```python
# Specific + actionable
sys.stderr.write("❌ Error: Direct python command blocked\n")
sys.stderr.write("💡 Detected Poetry project\n")
sys.stderr.write("   Use: poetry run python script.py\n")
```

**Bad Error Messages:**

```python
# Vague + not actionable
sys.stderr.write("Error\n")
sys.stderr.write("Command not allowed\n")
```

## Performance Constraints

### Keep Hooks Fast (<1ms ideal, <100ms acceptable)

**Fast validation (prefer):**

```python
# String containment check: O(n)
if 'forbidden' in cmd:
    sys.exit(2)

# Prefix check: O(n)
if cmd.startswith('forbidden'):
    sys.exit(2)
```

**Slow validation (avoid):**

```python
# Subprocess call: 50-200ms
import subprocess
result = subprocess.run(['complex-validator', cmd])

# Multiple file reads: 10-50ms each
for ref in multiple_refs:
    patterns = load_patterns(ref)
```

**Agent Optimization:**

1. Simple checks first (string operations)
2. Load references only if simple checks insufficient
3. Cache loaded references if possible

### Lazy Loading Pattern

**Correct (load only when needed):**

```python
# Fast path: no file I/O
if not needs_validation(cmd):
    sys.exit(0)

# Slow path: load only when required
patterns = load_patterns(ref_file)
validate(cmd, patterns)
```

**Incorrect (always loading):**

```python
# Always loads file, even if not needed
patterns = load_patterns(ref_file)
if needs_validation(cmd):
    validate(cmd, patterns)
```

### Caching Pattern

**When to cache:** References loaded frequently (every hook invocation)

```python
_pattern_cache = None

def get_patterns():
    """Cache patterns across invocations."""
    global _pattern_cache
    if _pattern_cache is None:
        _pattern_cache = load_patterns(ref_file)
    return _pattern_cache
```

**Note:** Claude Code may cache hook processes, making global caching effective.

## Common Implementation Errors

### ❌ Block All Commands

```python
# WRONG: Blocks everything
sys.exit(2)
```

**Fix:** Add validation logic before exit

### ❌ Fail Closed on Error

```python
# WRONG: Block if hook has bug
except Exception as e:
    sys.stderr.write(f"Error: {e}\n")
    sys.exit(2)
```

**Fix:** Fail-open (exit 0) for safety

```python
# CORRECT: Allow on error
except Exception:
    sys.exit(0)
```

### ❌ Hardcode Paths

```python
# WRONG: Hardcoded absolute path
ref_file = "/home/user/plugin/references/patterns.md"
```

**Fix:** Relative to script location

```python
# CORRECT: Relative to script
plugin_root = Path(__file__).parent.parent
ref_file = plugin_root / "references" / "patterns.md"
```

### ❌ Ignore Timeout

```python
# WRONG: Exceeds 1 second timeout
time.sleep(5)
import requests
requests.get('https://slow-api.com')
```

**Fix:** Keep logic fast, no network calls

### ❌ Missing Tool Filter

```python
# WRONG: Validates all tools (wasteful)
cmd = data.get('tool_input', {}).get('command', '')
if 'forbidden' in cmd:
    sys.exit(2)
```

**Fix:** Early exit for non-target tools

```python
# CORRECT: Filter by tool first
if tool != 'Bash':
    sys.exit(0)
```

## Testing Hooks

### Manual Testing

**Test hook script directly:**

```bash
# Test blocking case
echo '{"tool_name":"Bash","tool_input":{"command":"forbidden"}}' | \
  python3 scripts/validator.py
echo $?  # Should be 2 (blocked)

# Test allowing case
echo '{"tool_name":"Bash","tool_input":{"command":"safe"}}' | \
  python3 scripts/validator.py
echo $?  # Should be 0 (allowed)
```

### Automated Testing

**Agent workflow:** See [TESTING.md](../TESTING.md) for comprehensive test framework guide.

**Basic test pattern:**

```bash
run_test "Block forbidden command" \
    '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
    2 \
    "$HOOK_SCRIPT" \
    "Dangerous"
```

**Required test coverage:**

- Positive case (command allowed)
- Negative case (command blocked)
- Edge cases (empty input, invalid JSON, false positives)
- Error message validation (output pattern matching)

## Agent Implementation Checklist

**Before implementing hook:**

- [ ] Understand validation requirement (what to block/allow)
- [ ] Choose pattern (prefix, regex, alternatives, conditional)
- [ ] Decide if references/ needed (>50 patterns?)
- [ ] Decide if assets/ needed (templated errors?)

**During implementation:**

- [ ] Copy minimal pattern from "Core Implementation Pattern"
- [ ] Replace tool matcher
- [ ] Add validation logic
- [ ] Add error message with ❌ and 💡
- [ ] Add fail-open exception handler
- [ ] Test manually with echo/pipe

**After implementation:**

- [ ] Create test suite (positive, negative, edge cases)
- [ ] Validate error messages with pattern matching
- [ ] Run tests: `./test-framework.sh plugin/tests/test-*.sh`
- [ ] Verify performance (<100ms typical case)

## See Also

- [Plugin Architecture](./plugin-architecture.md) — Component structure and progressive disclosure
- [Hook Configuration Format](./hook-configuration.md) — hooks.json reference
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
- [Testing Guide](../TESTING.md) — Test framework and patterns
