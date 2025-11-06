---
description: Disable GitHub CLI security guard (allows all gh commands - use with caution)
allowed-tools: Read, Edit
---

⚠️ **WARNING:** This will disable write protection and allow ALL GitHub CLI commands.

**Tasks:**

1. Read `~/.claude/settings.json`
2. Set `githubCli.enabled` to `false`
3. Save the file

**Warning message:**

```
⚠️ GitHub CLI Security Guard Disabled

WARNING: All GitHub CLI write operations are now ALLOWED, including:
- gh api POST/PUT/PATCH/DELETE
- gh repo create/delete
- gh issue create/edit/close
- gh pr create/merge
- gh release create/delete

This means I can now:
❌ Delete repositories
❌ Close issues and PRs
❌ Merge pull requests
❌ Modify releases
❌ Make any GitHub API changes

Re-enable protection with: /gh-cli-enable
Check status: /gh-cli-status

Are you sure you want to proceed?
```
