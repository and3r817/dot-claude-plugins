---
description: Check GitHub CLI guard status
allowed-tools: Read
---

Check the GitHub CLI security guard status.

**Tasks:**

1. Read `~/.claude/settings.json` and check `githubWriteGuard.enabled` status (defaults to enabled if not set)
2. Display the status

**Output format:**

```
🛡️ GitHub CLI Security Guard

Status: [ENABLED/DISABLED]

The security guard blocks all GitHub CLI write operations:
- Repository modifications (create, delete, archive)
- PR/Issue changes (create, merge, close)
- API write methods (POST, PUT, PATCH, DELETE)
- Workflow operations (run, cancel)

Read operations are always allowed.
```
