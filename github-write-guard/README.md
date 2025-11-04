# GitHub Write Guard

Blocks GitHub CLI write operations while allowing read-only commands.

## Install

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install github-write-guard@dot-claude-plugins
```

## Usage/Behavior

- Default: guard is enabled; write operations are blocked
- Allowlisted write commands can be configured in settings

Blocked examples

- `gh repo delete …`, `gh pr merge …`, `gh api -X POST …`

Allowed examples

- `gh repo view …`, `gh pr view …`, `gh api <endpoint>` (GET)

Commands

- `/gh-guard-enable` – turn guard on
- `/gh-guard-disable` – temporarily disable
- `/gh-guard-status` – view current status

## Configure

`~/.claude/settings.json`:

```json
{
  "githubWriteGuard": {
    "enabled": true,
    "allowedWriteCommands": [],
    "logBlockedAttempts": true,
    "notifyOnBlock": false,
    "logPath": "~/.claude/logs/gh-write-guard.log"
  }
}
```

## Files

- `hooks/hooks.json` – PreToolUse hook wiring (Bash tool)
- `hooks/gh-write-blocker.sh` – Guard implementation
- `commands/*.md` – Enable/disable/status commands
- `.claude-plugin/plugin.json` – Plugin manifest

## Uninstall

```bash
/plugin uninstall github-write-guard
```
