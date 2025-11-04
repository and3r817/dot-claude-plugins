# Python Manager Enforcer

Enforces package manager usage by blocking direct python/python3 when a manager is detected and suggesting the correct alternative.

## Install

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install python-manager-enforcer@dot-claude-plugins
```

## Usage/Behavior

- Blocks: `python …`, `python3 …` in managed projects
- Allows: package manager bootstrapping like `python3 -m poetry …`
- Suggests: the right `… run python …` command for the detected manager

Supported managers: Poetry, UV, Rye, PDM, Hatch, Pixi, Conda/Mamba.

## Files

- `hooks/hooks.json` – PreToolUse hook wiring
- `scripts/enforce.py` – Manager detection and suggestion logic
- `.claude-plugin/plugin.json` – Plugin manifest

## Uninstall

```bash
/plugin uninstall python-manager-enforcer
```
