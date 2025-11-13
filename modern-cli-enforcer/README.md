# Modern CLI Tool Enforcer

Automatically enforces modern CLI tools over legacy commands in Bash operations.

## What It Does

**🔧 Enforcer Hook** - Blocks legacy CLI commands when modern alternatives are installed
**🎯 Smart Fallback** - Silently allows legacy commands when modern tools unavailable

**Supported Replacements**:
- `grep` → `ripgrep (rg)` - Fast parallel content search
- `find` → `fd` - User-friendly file finder with smart defaults
- `cat` → `bat` - Syntax highlighting with line numbers
- `ls` → `eza` - Modern ls with colors and git integration

## Requirements

**External Tools (Optional):**

The plugin works without these tools but provides no enforcement. Install any/all for enforcement:

- [ripgrep (`rg`)](https://github.com/BurntSushi/ripgrep) - Replaces `grep`
- [fd](https://github.com/sharkdp/fd) - Replaces `find`
- [bat](https://github.com/sharkdp/bat) - Replaces `cat`
- [eza](https://github.com/eza-community/eza) - Replaces `ls`

**Install Modern Tools:**

**macOS:**

```bash
brew install ripgrep fd bat eza
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt install ripgrep fd-find bat
cargo install eza
```

**Linux (Fedora/CentOS):**

```bash
sudo dnf install ripgrep fd-find bat
cargo install eza
```

**Linux (Arch):**

```bash
sudo pacman -S ripgrep fd bat eza
```

**Via Cargo (any platform):**

```bash
cargo install ripgrep fd-find bat eza
```

**Verify Installation:**

```bash
command -v rg && echo "✅ ripgrep installed"
command -v fd && echo "✅ fd installed"
command -v bat && echo "✅ bat installed"
command -v eza && echo "✅ eza installed"
```

## Install

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install modern-cli-enforcer@dot-claude-plugins
```

## Features

### Why Modern Tools?

**Performance**:
- **ripgrep**: 2-10x faster than grep (parallel search)
- **fd**: 3-5x faster than find (parallel traversal)
- **bat**: Syntax highlighting + line numbers
- **eza**: Git integration + better formatting

**Better Defaults**:
- Auto-ignore `.git`, `node_modules`, etc.
- Smart case-insensitive search
- Colored output by default
- Human-readable formats

**Improved UX**:
- Clear, consistent output formatting
- Better error messages
- Cross-platform compatibility

### How It Works

**Detection Logic:**

1. **Command Analysis** - Hook parses Bash command for legacy tool usage
2. **Availability Check** - Verifies if modern alternatives are installed
3. **Blocking** - If modern tool available, blocks legacy command with system reminder
4. **Fallback** - If modern tool unavailable, allows legacy command silently

**Example Behavior:**

**Scenario 1: Modern tool available (blocks)**
```bash
$ grep "TODO" src/**/*.py
```

**Output**:
```
⚠️  Legacy CLI tool(s) detected. Modern alternatives are available:

  • Use ripgrep (rg) instead of grep

**Why modern tools?**
  - Faster performance (parallel processing)
  - Better defaults (smart ignore patterns)
  - Improved UX (colors, formatting)

**Example replacements:**
  grep 'pattern' → rg 'pattern'

This command will be **blocked**. Please use modern alternatives.
```

**Scenario 2: Modern tool unavailable (allows)**
```bash
$ grep "TODO" src/**/*.py
```

**Output**: Command executes normally (no interruption)

## Plugin Structure

```
modern-cli-enforcer/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   └── hooks.json            # PreToolUse hook configuration
├── scripts/
│   └── enforce.py            # Enforcement logic
├── tests/
│   └── test-enforce.sh       # Test suite
└── README.md                 # This file
```

## Examples

### Example 1: Blocked Command (rg available)

**Command**:
```bash
grep "TODO" src/**/*.py
```

**Result**: ❌ Blocked with suggestion

**Fix**:
```bash
rg "TODO" src/**/*.py
```

### Example 2: Blocked Command (fd available)

**Command**:
```bash
find . -name "*.md"
```

**Result**: ❌ Blocked with suggestion

**Fix**:
```bash
fd "*.md"
```

### Example 3: Blocked Command (bat available)

**Command**:
```bash
cat README.md
```

**Result**: ❌ Blocked with suggestion

**Fix**:
```bash
bat README.md
```

### Example 4: Blocked Command (eza available)

**Command**:
```bash
ls -la
```

**Result**: ❌ Blocked with suggestion

**Fix**:
```bash
eza -la
```

### Example 5: Allowed Command (modern tool unavailable)

**Command**:
```bash
grep "TODO" src/**/*.py
```

**Context**: `rg` not installed

**Result**: ✅ Allowed (fallback to legacy grep)

## Testing

Run the test suite:

```bash
./run-all-tests.sh
# or
./test-framework.sh modern-cli-enforcer/tests/test-enforce.sh
```

Tests cover:
- Allow non-Bash commands
- Allow commands when modern tools unavailable
- Block legacy commands when modern tools available
- Detect commands in pipes and chains
- Handle edge cases (empty input, invalid JSON)
- Validate error messages

## Quick Reference: Command Replacements

| Legacy | Modern | Example |
|--------|--------|---------|
| `grep 'pattern' file` | `rg 'pattern' file` | `rg 'TODO' src/**/*.py` |
| `grep -r 'pattern' dir/` | `rg 'pattern' dir/` | `rg 'function' src/` |
| `grep -i 'pattern'` | `rg -i 'pattern'` | `rg -i 'error' logs/` |
| `find . -name '*.txt'` | `fd '*.txt'` | `fd '*.md'` |
| `find . -type f` | `fd --type f` | `fd --type f` |
| `find . -name 'test*'` | `fd '^test'` | `fd '^test'` |
| `cat file.py` | `bat file.py` | `bat README.md` |
| `cat -n file.txt` | `bat file.txt` | `bat -n config.json` |
| `ls -la` | `eza -la` | `eza -la --git` |
| `ls -lh` | `eza -lh` | `eza -lh --tree` |

## Troubleshooting

### Hook Not Triggering

**Check Installation**:
```bash
# Verify hook in settings.json
cat .claude/settings.json | jq '.hooks.PreToolUse'

# Restart Claude Code
```

**Verify Tool Availability**:
```bash
command -v rg fd bat eza
```

### Want to Temporarily Disable Hook

Uninstall the plugin:
```bash
/plugin uninstall modern-cli-enforcer
```

## Safety Features

✅ **Tool Availability Detection**: Only blocks if modern tool installed
✅ **Silent Fallback**: No interruption if modern tool unavailable
✅ **Fast Execution**: <5s timeout (PreToolUse requirement)
✅ **No Destructive Operations**: Read-only validation
✅ **Clear User Feedback**: System reminder with examples
✅ **Non-Breaking**: Can be disabled anytime

## Technical Details

**Event Type**: PreToolUse
**Tool Matcher**: Bash
**Timeout**: 1 second
**Exit Code**: 2 (blocking), 0 (allowing)
**Implementation**: Python 3
**Dependencies**: None (uses stdlib only)

**Detection Logic**: Token-based command parsing to avoid false positives (e.g., won't match "agrep" when looking for "grep")

## Uninstall

```bash
/plugin uninstall modern-cli-enforcer
```

## Learn More

**Modern CLI Tools**:
- [ripgrep (rg)](https://github.com/BurntSushi/ripgrep) - Fast grep alternative
- [fd](https://github.com/sharkdp/fd) - User-friendly find alternative
- [bat](https://github.com/sharkdp/bat) - cat with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement

**Claude Code Hooks**:
- [Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
- [Hook Examples](https://github.com/anthropics/claude-code/tree/main/examples/hooks)
