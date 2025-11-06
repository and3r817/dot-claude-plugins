---
description: Check GitHub CLI guard status and recent blocked attempts
allowed-tools: Read, Bash(bat:*), Bash(cat:*), Bash(wc:*), Bash(tail:*)
---

Check the GitHub CLI security guard status and show recent activity.

**Tasks:**

1. Read `~/.claude/settings.json` and check `githubCli.enabled` status
2. If the log file exists at `~/.claude/logs/gh-cli.log`, analyze it:

- Count total blocked attempts
- Show last 5 blocked commands

3. Display the configuration summary

**Output format:**

```
🛡️ GitHub CLI Security Guard Status

Status: [ENABLED/DISABLED]
Logging: [ENABLED/DISABLED]
Whitelist: [X commands allowed]

Recent Blocks (Last 5):
- [timestamp] command
- [timestamp] command

Statistics:
- Total blocks today: X
- Total blocks all time: X

Configuration:
- Log path: ~/.claude/logs/gh-cli.log
- Notifications: [ENABLED/DISABLED]
```
