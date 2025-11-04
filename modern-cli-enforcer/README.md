# Modern CLI Tool Enforcer Hook 🔧

**Automatically enforces modern CLI tools over legacy commands in Bash operations.**

---

## Overview

This PreToolUse hook intercepts Bash commands and blocks execution when legacy CLI tools are detected, suggesting modern alternatives instead. It only blocks when modern tools are available, falling back silently otherwise.

**Supported Replacements**:
- `grep` → `ripgrep (rg)` - Fast parallel content search
- `find` → `fd` - User-friendly file finder with smart defaults
- `cat` → `bat` - Syntax highlighting with line numbers
- `ls` → `eza` - Modern ls with colors and git integration

---

## Why Modern Tools?

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

---

## How It Works

### Detection Logic

1. **Command Analysis**: Hook parses Bash command for legacy tool usage
2. **Availability Check**: Verifies if modern alternatives are installed
3. **Blocking**: If modern tool available, blocks legacy command with system reminder
4. **Fallback**: If modern tool unavailable, allows legacy command silently

### Example Behavior

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

---

## Installation

### Option 1: Via Plugin Marketplace

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install modern-cli-enforcer@dot-claude-plugins
```

### Option 2: Manual Installation

#### 1. Install Modern Tools (if not already installed)

**macOS (Homebrew)**:
```bash
brew install ripgrep fd bat eza
```

**Linux (apt)**:
```bash
sudo apt install ripgrep fd-find bat
cargo install eza
```

**Linux (cargo)**:
```bash
cargo install ripgrep fd-find bat eza
```

**Verify Installation**:
```bash
command -v rg && echo "✅ ripgrep installed"
command -v fd && echo "✅ fd installed"
command -v bat && echo "✅ bat installed"
command -v eza && echo "✅ eza installed"
```

---

#### 2. Copy Plugin Files

Copy the plugin directory to your Claude Code plugins location or reference it directly in settings.

---

#### 3. Restart Claude Code

```bash
# Restart Claude Code to activate hook
# The hook will now validate all Bash commands
```

---

## File Structure

```
modern-cli-enforcer/
  ├── hooks/
  │   └── hooks.json          # Hook configuration
  ├── scripts/
  │   └── enforce.sh          # Enforcement logic
  ├── .claude-plugin/
  │   └── plugin.json         # Plugin manifest
  └── README.md               # Documentation
```

---

## Usage Examples

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

---

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

---

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

---

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

---

### Example 5: Allowed Command (modern tool unavailable)

**Command**:
```bash
grep "TODO" src/**/*.py
```

**Context**: `rg` not installed

**Result**: ✅ Allowed (fallback to legacy grep)

---

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

---

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

---

### Hook Blocking Too Aggressively

**Customize Tool List**: Edit `scripts/enforce.sh` and remove tools you want to allow from the `TOOL_MAP`:

```bash
# Tool mapping: legacy -> modern
declare -A TOOL_MAP=(
  ["grep"]="ripgrep (rg)"
  ["find"]="fd"
  # ["cat"]="bat"  # Commented out to allow cat
  ["ls"]="eza"
)
```

---

### Want to Temporarily Disable Hook

**Option 1: Remove from settings.json**
```json
{
  "hooks": {
    "PreToolUse": []
  }
}
```

**Option 2: Rename hook temporarily**
```bash
mv .claude/settings.json .claude/settings.json.backup
```

---

## Customization

### Add More Tools

Edit the `TOOL_MAP` in `scripts/enforce.sh`:

```bash
declare -A TOOL_MAP=(
  ["grep"]="ripgrep (rg)"
  ["find"]="fd"
  ["cat"]="bat"
  ["ls"]="eza"
  ["sed"]="sd"           # Add sd (modern sed replacement)
  ["diff"]="delta"       # Add delta (syntax-aware diff)
)
```

Add corresponding `check_tool_available` cases:

```bash
check_tool_available() {
  local legacy="$1"
  case "$legacy" in
    grep) command -v rg &>/dev/null ;;
    find) command -v fd &>/dev/null ;;
    cat) command -v bat &>/dev/null ;;
    ls) command -v eza &>/dev/null ;;
    sed) command -v sd &>/dev/null ;;
    diff) command -v delta &>/dev/null ;;
    *) return 1 ;;
  esac
}
```

---

### Change Behavior (Warn Instead of Block)

To allow execution with warning instead of blocking, edit `scripts/enforce.sh` and change `exit 2` to `exit 0`:

```bash
# Output error message but ALLOW execution
echo -e "$MESSAGE" >&2
exit 0  # Changed from exit 2 (blocks) to exit 0 (allows with warning)
```

---

## Safety Features

✅ **Tool Availability Detection**: Only blocks if modern tool installed
✅ **Silent Fallback**: No interruption if modern tool unavailable
✅ **Fast Execution**: <5s timeout (PreToolUse requirement)
✅ **No Destructive Operations**: Read-only validation
✅ **Clear User Feedback**: System reminder with examples
✅ **Non-Breaking**: Can be disabled anytime

---

## Technical Details

**Event Type**: PreToolUse
**Tool Matcher**: Bash only
**Timeout**: 1 second
**Exit Code**: 2 (blocking)
**Shell**: bash (portable)
**Dependencies**: jq (for JSON parsing)

**Detected Commands**: Uses regex word-boundary matching to avoid false positives (e.g., won't match "agrep" when looking for "grep")

---

## Uninstall

### Via Plugin System

```bash
/plugin uninstall modern-cli-enforcer
```

### Manual Uninstall

Remove the plugin directory and any references from your settings.

---

## Learn More

**Modern CLI Tools**:
- [ripgrep (rg)](https://github.com/BurntSushi/ripgrep) - Fast grep alternative
- [fd](https://github.com/sharkdp/fd) - User-friendly find alternative
- [bat](https://github.com/sharkdp/bat) - cat with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement

**Claude Code Hooks**:
- [Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
- [Hook Examples](https://github.com/anthropics/claude-code/tree/main/examples/hooks)

---

**Version**: 1.0.0
**Date**: 2025-11-04

🚀 **Enjoy faster, more powerful CLI workflows!**
