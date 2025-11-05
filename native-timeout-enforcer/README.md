# Native Timeout Enforcer

Prevents use of timeout/gtimeout in Bash; use the Bash tool’s native timeout parameter instead.

## Install

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install native-timeout-enforcer@dot-claude-plugins
```

## Usage/Behavior

- Blocks `timeout` or `gtimeout` in Bash commands (including in pipes/chains)
- Suggests using the Bash tool’s `timeout` parameter (milliseconds)

Examples:
- Blocked: `timeout 5 python long_script.py`
- Recommended: `Bash(command="python long_script.py", timeout=5000)`

## Files

- `hooks/hooks.json` – PreToolUse hook to validate commands
- `scripts/validate-timeout.sh` – Validation script
- `.claude-plugin/plugin.json` – Plugin manifest

## Uninstall

```bash
/plugin uninstall native-timeout-enforcer
```
