# My Claude Code Plugins

A small collection of plugins I use with Claude Code.

## Install Marketplace

```bash
/plugin marketplace add and3r817/dot-claude-plugins
```

## Plugins

- [github-write-guard](./github-write-guard/README.md) – Blocks GitHub CLI write operations; allows read-only.

- [native-timeout-enforcer](./native-timeout-enforcer/README.md) – Prevents use of timeout/gtimeout in Bash; use the Bash tool’s native timeout parameter instead.

- [python-manager-enforcer](./python-manager-enforcer/README.md) – Enforces package manager usage by blocking direct python/python3 when a manager is detected and suggesting the correct alternative.

## Manage

```bash
# List installed
/plugin list

# Uninstall
/plugin uninstall <plugin>
```
