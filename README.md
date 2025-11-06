# Claude Code Plugins

A small collection of plugins I use with Claude Code.

## Install Marketplace

```bash
/plugin marketplace add and3r817/dot-claude-plugins
```

## Plugins

- [github-cli](./github-cli/README.md) – GitHub CLI (gh) companion: security guard blocking write operations + comprehensive usage skill for automation, API access, and workflows.

- [modern-cli-enforcer](./modern-cli-enforcer/README.md) – Enforces modern CLI tools (rg, fd, bat, eza) over legacy commands (grep, find, cat, ls).

- [native-timeout-enforcer](./native-timeout-enforcer/README.md) – Prevents use of timeout/gtimeout in Bash; use the Bash tool's native timeout parameter instead.

- [python-manager-enforcer](./python-manager-enforcer/README.md) – Enforces package manager usage by blocking direct python/python3 when a manager is detected and suggesting the correct alternative.

## Manage

```bash
# List installed
/plugin list

# Uninstall
/plugin uninstall <plugin>
```
