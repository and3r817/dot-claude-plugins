# Plugin Marketplace Publishing Guide

**Agent Context**: Read when publishing plugin to marketplace or configuring marketplace structure. Quick reference for
marketplace.json and repository publishing.

## When to Consult This Document

**READ when:**

- Adding plugin to repository marketplace
- Creating new marketplace structure
- Validating marketplace.json syntax
- Understanding plugin discovery mechanism
- Debugging plugin installation issues

**SKIP when:**

- Working on plugin implementation (not publishing)
- Only testing plugin locally
- Plugin not ready for distribution

## Repository Structure

### This Repository Marketplace

**Path**: `.claude-plugin/marketplace.json`

**Structure:**

```
dot-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace registry
├── plugin-1/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── ...
├── plugin-2/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── ...
└── README.md
```

**Agent Investigation Pattern:**

1. Check `.claude-plugin/marketplace.json` for plugin list
2. Each plugin entry has `source` field pointing to plugin directory
3. Plugin directory contains `.claude-plugin/plugin.json`

### marketplace.json Structure

**Minimal marketplace:**

```json
{
  "name": "marketplace-name",
  "description": "Collection description",
  "owner": "github-username",
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugin-directory",
      "description": "What plugin does",
      "tags": ["tag1", "tag2", "tag3"]
    }
  ]
}
```

**Agent Implementation:**

1. Add plugin entry to `plugins` array
2. Set `source` to plugin directory (relative path)
3. Copy description from plugin.json
4. Add 3-7 relevant tags
5. Validate JSON syntax

## Marketplace Fields Reference

### Required Fields

#### name

**Type:** String
**Format:** `lowercase-with-hyphens`

**Purpose:** Marketplace identifier

```json
{
  "name": "dot-claude-plugins"
}
```

**Agent Usage:** User references this when adding marketplace:

```
/plugin marketplace add and3r817/dot-claude-plugins
```

#### description

**Type:** String
**Max length:** 500 characters (recommend <200)

**Purpose:** Marketplace overview shown to users

```json
{
  "description": "Collection of Claude Code plugins for enforcing best practices, security, and modern tooling standards"
}
```

**Agent Requirements:**

- Describe marketplace theme/purpose
- Summarize plugin categories
- Keep concise (<200 chars ideal)

#### plugins

**Type:** Array of plugin objects

**Purpose:** Registry of available plugins

```json
{
  "plugins": [
    {
      "name": "plugin-1",
      "source": "./plugin-1",
      "description": "Description",
      "tags": ["tag1", "tag2"]
    },
    {
      "name": "plugin-2",
      "source": "./plugin-2",
      "description": "Description",
      "tags": ["tag1", "tag2"]
    }
  ]
}
```

**Agent Actions:**

- Add new plugin entry when plugin ready
- Keep alphabetically sorted for readability
- Validate all source paths exist

### Optional Fields

#### owner

**Type:** String

**Purpose:** GitHub username or organization

```json
{
  "owner": "and3r817"
}
```

**Agent Usage:** For this repository, use `"and3r817"`

#### url

**Type:** String

**Purpose:** Repository URL

```json
{
  "url": "https://github.com/and3r817/dot-claude-plugins"
}
```

**Agent Usage:** Include for external marketplace references

## Plugin Entry Structure

### Required Plugin Fields

#### name

**Type:** String
**Format:** `lowercase-with-hyphens`

**CRITICAL:** MUST match plugin's .claude-plugin/plugin.json name field

```json
{
  "plugins": [
    {
      "name": "github-cli"  // Must match plugin.json name
    }
  ]
}
```

**Validation:**

```bash
# Verify name matches
jq -r '.name' github-cli/.claude-plugin/plugin.json
# Should output: github-cli
```

#### source

**Type:** String

**Purpose:** Relative path from marketplace.json to plugin directory

**Format:** `./plugin-directory`

```json
{
  "plugins": [
    {
      "name": "github-cli",
      "source": "./github-cli"  // Relative to marketplace.json
    }
  ]
}
```

**Agent Rules:**

- MUST be relative path starting with `./`
- Points to directory containing `.claude-plugin/plugin.json`
- Use forward slashes (Unix-style)

**Validation:**

```bash
# Check path exists
ls ./github-cli/.claude-plugin/plugin.json
```

#### description

**Type:** String
**Max length:** 500 characters (recommend <200)

**Purpose:** Plugin description shown in marketplace listing

**CRITICAL:** Should match or extend plugin.json description

```json
{
  "plugins": [
    {
      "name": "github-cli",
      "description": "GitHub CLI companion: security guard + comprehensive usage skill"
    }
  ]
}
```

**Agent Action:** Copy from plugin.json description field

#### tags

**Type:** Array of strings

**Purpose:** Plugin categorization for discovery

```json
{
  "plugins": [
    {
      "name": "github-cli",
      "tags": ["github", "gh", "cli", "security", "skill", "hybrid"]
    }
  ]
}
```

**Tag Selection Guidelines:**

**Functionality tags:**

- `enforcement` — Blocks/validates commands
- `security` — Security-focused
- `automation` — Workflow automation
- `advisory` — Provides guidance/consultation

**Type tags:**

- `hook` — Hook plugin
- `skill` — Skill plugin
- `command` — Command plugin
- `hybrid` — Multiple components

**Technology tags:**

- `python` — Python-related
- `github` — GitHub integration
- `docker` — Docker tools
- `bash` — Bash/shell scripts

**Agent Implementation:**

```
For each plugin:
1. Identify functionality (enforcement, security, automation, advisory)
2. Identify type (hook, skill, command, hybrid)
3. Identify technology (python, github, docker, etc.)
4. Select 3-7 most relevant tags
```

**Example tag selection:**

| Plugin                  | Functionality      | Type   | Technology      | Tags                                                     |
|-------------------------|--------------------|--------|-----------------|----------------------------------------------------------|
| github-cli              | security, advisory | hybrid | github, gh, cli | `["github", "gh", "cli", "security", "skill", "hybrid"]` |
| python-manager-enforcer | enforcement        | hook   | python          | `["python", "package-manager", "enforcement", "hook"]`   |
| codex-advisor           | advisory           | skill  | architecture    | `["advisory", "architecture", "consultation", "skill"]`  |

## Adding Plugin to Marketplace

### Step-by-Step Workflow

**Agent Execution Order:**

#### Step 1: Validate Plugin Ready

```bash
# Check plugin structure complete
ls plugin-name/.claude-plugin/plugin.json  # ✅ Exists
ls plugin-name/README.md                   # ✅ Exists
ls plugin-name/tests/                      # ✅ Exists

# Validate plugin.json
python3 -m json.tool plugin-name/.claude-plugin/plugin.json

# Run plugin tests
./test-framework.sh plugin-name/tests/test-*.sh
```

**Agent Checkpoint:**

- [ ] plugin.json validates
- [ ] README.md complete
- [ ] Tests pass
- [ ] All JSON files validate

#### Step 2: Read Plugin Metadata

```bash
# Extract name and description
NAME=$(jq -r '.name' plugin-name/.claude-plugin/plugin.json)
DESC=$(jq -r '.description' plugin-name/.claude-plugin/plugin.json)

echo "Name: $NAME"
echo "Description: $DESC"
```

**Agent Action:** Use extracted values for marketplace entry

#### Step 3: Determine Tags

**Agent Decision Tree:**

```
Plugin has hooks/hooks.json?
├─ YES → Add "hook" tag
└─ NO → Skip

Plugin has skills/ directory?
├─ YES → Add "skill" tag
└─ NO → Skip

Plugin has commands in plugin.json?
├─ YES → Add "command" tag
└─ NO → Skip

Multiple components?
├─ YES → Add "hybrid" tag
└─ NO → Skip

What does plugin enforce/provide?
├─ Blocks commands → Add "enforcement"
├─ Security checks → Add "security"
├─ Automates workflow → Add "automation"
└─ Provides guidance → Add "advisory"

What technology does plugin relate to?
└─ Add technology tags (python, github, docker, etc.)
```

#### Step 4: Add to marketplace.json

**Agent Action:** Read marketplace.json, add plugin entry, write back

```python
#!/usr/bin/env python3
import json

# Read marketplace
with open('.claude-plugin/marketplace.json') as f:
    marketplace = json.load(f)

# Add plugin
marketplace['plugins'].append({
    "name": "plugin-name",
    "source": "./plugin-name",
    "description": "Plugin description",
    "tags": ["tag1", "tag2", "tag3"]
})

# Sort plugins alphabetically by name
marketplace['plugins'].sort(key=lambda p: p['name'])

# Write back
with open('.claude-plugin/marketplace.json', 'w') as f:
    json.dump(marketplace, f, indent=2)
    f.write('\n')  # Trailing newline
```

**Agent Checkpoint:**

- [ ] Plugin entry added
- [ ] Plugins sorted alphabetically
- [ ] JSON validates
- [ ] Source path correct

#### Step 5: Validate Marketplace

```bash
# Validate JSON syntax
python3 -m json.tool .claude-plugin/marketplace.json

# Verify all source paths exist
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f:
    marketplace = json.load(f)
    for plugin in marketplace['plugins']:
        source = plugin['source']
        plugin_json = f\"{source}/.claude-plugin/plugin.json\"
        with open(plugin_json) as pf:
            plugin_data = json.load(pf)
            print(f\"✓ {plugin['name']} - {source}\")
"
```

**Agent Checkpoint:**

- [ ] marketplace.json validates
- [ ] All source paths exist
- [ ] All plugin.json files validate

#### Step 6: Update Root README

**Agent Action:** Add plugin to root README.md plugins list

```markdown
## Plugins

- [codex-advisor](./codex-advisor/README.md) – Advisory consultation skill for architectural reviews and design decisions.
- [github-cli](./github-cli/README.md) – GitHub CLI companion: security guard + comprehensive usage skill.
- [modern-cli-enforcer](./modern-cli-enforcer/README.md) – Enforces modern CLI tools (rg, fd, bat, eza) over legacy commands.
- [native-timeout-enforcer](./native-timeout-enforcer/README.md) – Blocks timeout/gtimeout commands, suggests Bash tool's timeout parameter.
- [plugin-name](./plugin-name/README.md) – New plugin description here.
- [python-manager-enforcer](./python-manager-enforcer/README.md) – Enforces package manager usage by blocking direct python/python3 in managed projects.
```

**Agent Rules:**

- Keep alphabetically sorted
- Use relative links to README
- Use concise description (from plugin.json)

**Agent Checkpoint:**

- [ ] Plugin added to README
- [ ] List alphabetically sorted
- [ ] Link to plugin README correct

## Local Development Marketplace

**Use case:** Test plugin locally before publishing

### Setup Pattern

**Agent Implementation:**

```bash
# Create dev marketplace directory
mkdir -p dev-marketplace/.claude-plugin

# Create marketplace.json
cat > dev-marketplace/.claude-plugin/marketplace.json << 'EOF'
{
  "name": "dev-marketplace",
  "description": "Local development marketplace",
  "plugins": [
    {
      "name": "my-plugin",
      "source": "../my-plugin",
      "description": "Plugin under development",
      "tags": ["development", "testing"]
    }
  ]
}
EOF
```

**In Claude Code:**

```
/plugin marketplace add ./dev-marketplace
/plugin install my-plugin@dev-marketplace
```

**Agent Workflow:**

1. Make changes to plugin files
2. Uninstall: `/plugin uninstall my-plugin`
3. Reinstall: `/plugin install my-plugin@dev-marketplace`
4. Test functionality
5. Repeat until working

### Testing Cycle

**Agent Pattern:**

```
1. Edit plugin files (hooks, scripts, SKILL.md, etc.)
2. Run tests: ./test-framework.sh plugin/tests/test-*.sh
3. Uninstall from Claude Code
4. Reinstall from dev marketplace
5. Test in Claude Code
6. Repeat steps 1-5 until working
7. Add to production marketplace
```

## GitHub Repository Publishing

**Use case:** Share marketplace publicly

### Repository Structure

**Recommended:**

```
username/repository/
├── .claude-plugin/
│   └── marketplace.json
├── plugin-1/
│   └── .claude-plugin/plugin.json
├── plugin-2/
│   └── .claude-plugin/plugin.json
├── README.md
└── LICENSE
```

### Installation Pattern

**Users install via:**

```
/plugin marketplace add username/repository
/plugin install plugin-name@username/repository
```

**Agent Documentation Pattern for README:**

```markdown
# Marketplace Name

Description of marketplace and plugins.

## Installation

Add marketplace:
```

/plugin marketplace add username/repository

```

Install plugin:
```

/plugin install plugin-name@username/repository

```

## Available Plugins

- **plugin-1** – Description
- **plugin-2** – Description

See individual plugin READMEs for details.
```

## Validation

### Marketplace JSON Syntax

```bash
# Validate syntax
python3 -m json.tool .claude-plugin/marketplace.json
```

### Source Path Validation

```bash
# Verify all paths exist
python3 << 'EOF'
import json
import os

with open('.claude-plugin/marketplace.json') as f:
    marketplace = json.load(f)

errors = []
for plugin in marketplace['plugins']:
    source = plugin['source']
    plugin_json_path = os.path.join(source, '.claude-plugin', 'plugin.json')

    if not os.path.exists(plugin_json_path):
        errors.append(f"Missing: {plugin_json_path}")
    else:
        # Validate name matches
        with open(plugin_json_path) as pf:
            plugin_data = json.load(pf)
            if plugin_data.get('name') != plugin['name']:
                errors.append(f"Name mismatch: {plugin['name']} != {plugin_data.get('name')}")

if errors:
    for error in errors:
        print(f"❌ {error}")
    exit(1)
else:
    print("✅ All plugins validated")
EOF
```

### Name Consistency Check

```bash
# Verify marketplace name matches plugin.json name
python3 << 'EOF'
import json

with open('.claude-plugin/marketplace.json') as f:
    marketplace = json.load(f)

for plugin in marketplace['plugins']:
    source = plugin['source']
    with open(f"{source}/.claude-plugin/plugin.json") as pf:
        plugin_data = json.load(pf)
        marketplace_name = plugin['name']
        plugin_json_name = plugin_data['name']

        if marketplace_name != plugin_json_name:
            print(f"❌ {source}: marketplace={marketplace_name}, plugin.json={plugin_json_name}")
        else:
            print(f"✅ {marketplace_name}")
EOF
```

## Common Errors

### Wrong Source Path

**Error:**

```json
{
  "plugins": [
    {
      "source": "github-cli"  // ❌ Missing ./
    }
  ]
}
```

**Fix:**

```json
{
  "plugins": [
    {
      "source": "./github-cli"  // ✅ Relative path
    }
  ]
}
```

### Name Mismatch

**marketplace.json:**

```json
{
  "name": "github-cli-plugin"  // ❌ Doesn't match plugin.json
}
```

**plugin.json:**

```json
{
  "name": "github-cli"
}
```

**Fix:** Names must match exactly

```json
{
  "name": "github-cli"  // ✅ Matches plugin.json
}
```

### Absolute Path

**Error:**

```json
{
  "source": "/Users/user/plugins/github-cli"  // ❌ Absolute
}
```

**Fix:**

```json
{
  "source": "./github-cli"  // ✅ Relative
}
```

## Troubleshooting Decision Trees

### Issue: Plugin Not Appearing in Marketplace

**Investigation:**

```
Plugin not listed in /plugin marketplace?
│
├─ marketplace.json exists?
│  └─ ls .claude-plugin/marketplace.json
│
├─ JSON valid?
│  └─ python3 -m json.tool .claude-plugin/marketplace.json
│
├─ Plugin in plugins array?
│  └─ jq '.plugins[] | select(.name=="plugin-name")' .claude-plugin/marketplace.json
│
└─ Marketplace added to Claude Code?
   └─ /plugin marketplace list
```

### Issue: Plugin Installation Fails

**Investigation:**

```
Cannot install plugin from marketplace?
│
├─ Source path correct?
│  └─ ls ./plugin-name/.claude-plugin/plugin.json
│
├─ Plugin.json valid?
│  └─ python3 -m json.tool plugin-name/.claude-plugin/plugin.json
│
├─ Name matches?
│  └─ Compare marketplace.json name with plugin.json name
│
└─ All required files present?
   └─ ls plugin-name/{.claude-plugin/plugin.json,README.md}
```

## Agent Implementation Checklist

**Before adding plugin to marketplace:**

- [ ] Plugin implementation complete
- [ ] Tests pass (./test-framework.sh)
- [ ] README.md written
- [ ] plugin.json validates
- [ ] All JSON files validate

**During marketplace addition:**

- [ ] Read plugin name from plugin.json
- [ ] Read description from plugin.json
- [ ] Determine tags (3-7 tags)
- [ ] Add entry to marketplace.json plugins array
- [ ] Sort plugins alphabetically
- [ ] Validate marketplace.json syntax

**After marketplace addition:**

- [ ] Validate all source paths exist
- [ ] Verify name consistency (marketplace vs plugin.json)
- [ ] Update root README.md plugin list
- [ ] Test installation locally
- [ ] Run all tests (./run-all-tests.sh)

## Best Practices

### Do's ✅

**Structure:**

- Keep plugins alphabetically sorted
- Use relative paths (./plugin-name)
- Validate JSON after every edit
- Verify source paths exist

**Tags:**

- Include 3-7 relevant tags
- Use consistent tag vocabulary
- Include functionality, type, and technology tags
- Make discoverable (think what users search for)

**Consistency:**

- Match plugin.json name exactly
- Copy description from plugin.json
- Keep marketplace.json and README in sync

### Don'ts ❌

**Structure:**

- Don't use absolute paths
- Don't use Windows-style paths (backslashes)
- Don't forget trailing newline in JSON
- Don't leave plugins unsorted

**Tags:**

- Don't use too few tags (<3)
- Don't use too many tags (>7)
- Don't use vague tags ("plugin", "tool")
- Don't invent new tag categories (use standard ones)

**Consistency:**

- Don't mismatch names (marketplace vs plugin.json)
- Don't skip validation before committing
- Don't forget to update README

## See Also

- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json structure
- [Adding a New Plugin](./adding-new-plugin.md) — Step 6: Repository Integration
- [Plugin Architecture](./plugin-architecture.md) — Component structure overview
