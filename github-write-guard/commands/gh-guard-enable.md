---
description: Enable GitHub Write Guard protection (blocks all gh write operations)
allowed-tools: Read, Edit
---

Enable the GitHub Write Guard to block all GitHub CLI write operations.

**Tasks:**

1. Read `~/.claude/settings.json`
2. If `githubWriteGuard` section doesn't exist, create it:
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
3. If it exists, set `githubWriteGuard.enabled` to `true`
4. Save the file

**Success message:**

```
✅ GitHub Write Guard Enabled

Protection is now active. The following will be blocked:
- gh api POST/PUT/PATCH/DELETE requests
- gh repo create/delete/fork
- gh issue create/edit/close
- gh pr create/edit/merge
- gh release create/delete
- All other write operations

Read-only commands (view, list, status) are still allowed.

Disable with: /gh-guard-disable
Check status: /gh-guard-status
```
