---
name: bump-version
description: "Bump semver version for single or multiple plugins based on change analysis"
allowed-tools: Read, Edit, Glob, Grep, Bash(git diff:*), Bash(git status:*), Bash(jq:*), AskUserQuestion
argument-hint: "[plugin-name|all] [major|minor|patch|auto]"
---

## CONTEXT

Git status: !`git status --short`
Changed plugins: !
`git status --short | grep -E "plugin\.json|SKILL\.md|scripts/|hooks/" | cut -d'/' -f1 | sort -u | head -20`

## INSTRUCTIONS

${1:?Error: Plugin name required. Usage: /bump-version <plugin-name|all> [major|minor|patch|auto]}

# Version Bump: $1

**Bump type:** ${2:-auto}

## SEMVER DECISION MATRIX

Use this matrix to determine appropriate version bump:

### MAJOR (X.0.0) — Breaking Changes

| Trigger                       | Example                            |
|-------------------------------|------------------------------------|
| Complete rewrite              | SKILL.md structure changed         |
| Incompatible API changes      | Hook contract changed              |
| Remove documented behavior    | Removed allowed-tools              |
| Drop runtime/platform support | Changed Python version requirement |

### MINOR (x.Y.0) — New Features, Backward Compatible

| Trigger                   | Example                             |
|---------------------------|-------------------------------------|
| New capability added      | Added `Bash(sg:*)` to allowed-tools |
| Content removal (notable) | Removed documentation section       |
| Behavior config change    | Model version updated               |
| Functionality deprecated  | Marked feature for removal          |
| New reference files       | Added new reference docs            |

### PATCH (x.y.Z) — Fixes, No Functional Changes

| Trigger                | Example                     |
|------------------------|-----------------------------|
| Metadata additions     | Added homepage/repository   |
| Internal restructuring | Moved references to skills/ |
| Formatting changes     | Multi-line to single line   |
| Typo/doc fixes         | Fixed spelling              |
| Bug fixes              | Fixed script logic          |

## PROCESS

### Step 1: Identify Target Plugins

If `$1` is "all":

- Find all plugins with changes using git status
- List plugins with modified plugin.json or SKILL.md

If `$1` is specific plugin:

- Verify plugin exists at `$1/.claude-plugin/plugin.json`

### Step 2: Analyze Changes Per Plugin

For each target plugin:

1. **Read current version** from plugin.json
2. **Get git diff** for plugin directory:
   ```
   git diff HEAD -- $PLUGIN_DIR/
   ```
3. **Categorize changes** using SEMVER DECISION MATRIX:
    - Check for SKILL.md structure changes (MAJOR indicator)
    - Check for allowed-tools modifications (MINOR if added, MAJOR if removed)
    - Check for reference file additions/moves (MINOR if new, PATCH if moved)
    - Check for plugin.json metadata changes (PATCH)
    - Check for formatting-only changes (PATCH)

### Step 3: Determine Version Bump

If bump type is `auto`:

- Apply SEMVER DECISION MATRIX
- Use highest applicable bump (mixed changes → highest wins)
- Present recommendation with rationale

If bump type is explicit (`major`/`minor`/`patch`):

- Use specified bump type
- Warn if recommendation differs

### Step 4: Calculate New Version

Current: `X.Y.Z`

- MAJOR: `X+1.0.0`
- MINOR: `X.Y+1.0`
- PATCH: `X.Y.Z+1`

### Step 5: Update plugin.json

Use Edit tool to update version field:

```json
"version": "NEW_VERSION"
```

### Step 6: Summary Report

## OUTPUT FORMAT

```markdown
## Version Bump Summary

| Plugin | Current | Changes | Bump | New |
|--------|---------|---------|------|-----|
| plugin-name | 1.0.0 | [summary] | MINOR | 1.1.0 |

### Change Analysis

#### plugin-name (1.0.0 → 1.1.0) — MINOR

**Triggers detected:**

- [MINOR] Added `Bash(sg:*)` to allowed-tools
- [PATCH] Added homepage metadata

**Highest applicable:** MINOR

**Files updated:**

- ✅ plugin-name/.claude-plugin/plugin.json
```

## EXAMPLES

### Single plugin, auto-detect

```
/bump-version ast-grep
```

### Single plugin, explicit bump

```
/bump-version github-cli minor
```

### All changed plugins

```
/bump-version all auto
```

### All plugins, specific bump

```
/bump-version all patch
```

## ERROR HANDLING

- **Plugin not found:** List available plugins
- **No changes detected:** Skip with message (for auto mode)
- **Invalid bump type:** Show valid options
- **Version parse error:** Show current plugin.json content

## VALIDATION

After updates, verify:

1. plugin.json is valid JSON (use `jq .`)
2. Version follows semver format (X.Y.Z)
3. No uncommitted structural issues
