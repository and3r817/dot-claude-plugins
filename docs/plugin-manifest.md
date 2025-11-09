# Plugin Manifest Format Reference

**Agent Context**: Quick reference for plugin.json structure. Consult when writing or validating manifests.

## When to Consult This Document

**READ when:**

- Writing plugin.json for new plugin
- Validating manifest syntax
- Understanding which fields are required vs optional
- Determining what NOT to include (skills, hooks)

**SKIP when:**

- You already know minimal manifest structure
- Only need to validate syntax (use `python3 -m json.tool`)

## Location

**Required path:** `.claude-plugin/plugin.json`

**CRITICAL:** All plugins MUST have this file at this exact location.

## Minimal Required Manifest

**Start with this:**

```json
{
  "name": "my-plugin",
  "description": "What this plugin does"
}
```

**Sufficient for:**

- Skills-only plugins (auto-discovered from skills/)
- Hook plugins (hooks.json auto-loaded from hooks/)
- Plugins without commands

**Agent Action:** Start minimal, expand to production version after testing.

## Production Manifest

**Expand to this after basic validation:**

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Comprehensive description",
  "author": {
    "name": "and3r817",
    "url": "https://github.com/and3r817"
  },
  "license": "MIT",
  "keywords": ["tag1", "tag2"]
}
```

**Add commands only if commands/ directory exists:**

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "...",
  "commands": [
    "./commands/my-command.md"
  ]
}
```

## Field Reference

### Required Fields

#### name

**Type:** String
**Format:** `lowercase-with-hyphens`
**Max length:** 64 characters

**Validation Rules:**

- Lowercase letters only
- Numbers allowed
- Hyphens allowed as separators
- NO spaces, underscores, or uppercase

**Valid:**

```json
"name": "github-cli"
"name": "my-plugin-123"
```

**Invalid:**

```json
"name": "GitHub CLI"      // ❌ Spaces
"name": "my_plugin"       // ❌ Underscores
"name": "MyPlugin"        // ❌ Uppercase
```

#### description

**Type:** String
**Max length:** 1024 characters
**Recommended:** <200 characters for readability

**Agent Requirements:**

- MUST be specific about functionality
- MUST be actionable (explain what it does, not what it is)
- For skill plugins: include trigger keywords

**Good:**

```json
"description": "Enforces modern CLI tools (rg, fd, bat, eza) over legacy commands"
```

**Bad:**

```json
"description": "A plugin"  // ❌ Too vague
```

### Optional Fields

#### version

**Type:** String
**Format:** Semantic versioning (`MAJOR.MINOR.PATCH`)

```json
"version": "1.0.0"    // Initial release
"version": "1.2.3"    // Minor feature + patch
"version": "2.0.0"    // Breaking changes
```

**Agent Default:** Use `"1.0.0"` for new plugins.

#### author

**Type:** Object

```json
"author": {
  "name": "and3r817",
  "email": "email@example.com",  // Optional
  "url": "https://github.com/and3r817"
}
```

**Required subfields:**

- `name` (string) — Author name or handle

**Optional subfields:**

- `email` (string) — Contact email
- `url` (string) — GitHub profile or website

**Agent Default:** Use `and3r817` for this repository.

#### license

**Type:** String

```json
"license": "MIT"
```

**Common values:** MIT, Apache-2.0, GPL-3.0, BSD-3-Clause, ISC

**Agent Default:** Use `"MIT"` for this repository.

#### keywords

**Type:** Array of strings

```json
"keywords": ["github", "cli", "security", "hook"]
```

**Agent Selection Guidelines:**

- Include 3-7 keywords
- Functionality: "enforcement", "security", "automation", "advisory"
- Type: "hook", "skill", "command", "hybrid"
- Technology: "python", "github", "docker", "bash"

**Examples by plugin type:**

- Hook: `["python", "package-manager", "enforcement", "hook"]`
- Skill: `["advisory", "architecture", "consultation", "skill"]`
- Hybrid: `["github", "gh", "cli", "security", "skill", "hybrid"]`

#### commands

**Type:** Array of strings (paths)

```json
"commands": [
  "./commands/deploy.md",
  "./commands/status.md"
]
```

**Agent Rules:**

- ONLY include if commands/ directory exists with .md files
- Paths relative to plugin root
- Use forward slashes (Unix-style), NOT backslashes
- Must point to .md files with frontmatter

**Example:**

```
my-plugin/
├── commands/
│   ├── deploy.md
│   └── status.md
└── .claude-plugin/
    └── plugin.json  →  "commands": ["./commands/deploy.md", "./commands/status.md"]
```

## Critical: What NOT to Include

### ❌ DO NOT List Skills

**Skills are auto-discovered** from `skills/` directory.

**WRONG:**

```json
{
  "skills": ["./skills/my-skill/SKILL.md"]  // ❌ Never do this
}
```

**CORRECT:**

```
my-plugin/
└── skills/
    └── my-skill/
        └── SKILL.md  // ✅ Auto-discovered, no manifest entry
```

**Agent Action:** If you see `"skills"` field in plugin.json, REMOVE it.

### ❌ DO NOT List Hooks

**Hooks configuration is auto-loaded** from `hooks/hooks.json`.

**WRONG:**

```json
{
  "hooks": "./hooks/hooks.json"  // ❌ Never do this
}
```

**CORRECT:**

```
my-plugin/
└── hooks/
    └── hooks.json  // ✅ Auto-loaded, no manifest entry
```

**Agent Action:** If you see `"hooks"` field in plugin.json, REMOVE it.

### ❌ DO NOT List Tests, References, Assets, Scripts

Supporting files are NOT referenced in manifest.

**ONLY commands need explicit paths.**

## Validation

### JSON Syntax Check

```bash
# Validate syntax
python3 -m json.tool .claude-plugin/plugin.json

# Or with jq
jq . .claude-plugin/plugin.json
```

**Agent Action:** Run validation after writing/modifying plugin.json.

### Common Syntax Errors

**Trailing comma:**

```json
{
  "name": "my-plugin",
  "description": "Description",  // ❌ Trailing comma before }
}
```

**Fix:** Remove trailing comma.

**Missing quotes on keys:**

```json
{
  name: "my-plugin",  // ❌ Key not quoted
  "description": "Description"
}
```

**Fix:** Quote all keys.

**Windows-style paths:**

```json
{
  "commands": [
    ".\\commands\\cmd.md"  // ❌ Backslashes
  ]
}
```

**Fix:** Use forward slashes.

```json
{
  "commands": [
    "./commands/cmd.md"  // ✅ Forward slashes
  ]
}
```

## Examples by Plugin Type

### Hook Plugin (Enforcement)

**Characteristics:**

- Has hooks/ directory
- No skills/ directory
- No commands/ directory

**Manifest:**

```json
{
  "name": "python-manager-enforcer",
  "version": "1.0.0",
  "description": "Enforces package manager usage by blocking direct python/python3",
  "author": {
    "name": "and3r817",
    "url": "https://github.com/and3r817"
  },
  "license": "MIT",
  "keywords": ["python", "package-manager", "enforcement", "hook"]
}
```

**Note:** No commands, no skills. Hooks auto-loaded from hooks/hooks.json.

### Skill Plugin (Capability)

**Characteristics:**

- Has skills/ directory
- No hooks/ directory
- May have commands/ directory

**Manifest:**

```json
{
  "name": "codex-advisor",
  "version": "1.0.0",
  "description": "Advisory consultation skill for architectural reviews and design decisions",
  "author": {
    "name": "and3r817",
    "url": "https://github.com/and3r817"
  },
  "license": "MIT",
  "keywords": ["advisory", "architecture", "consultation", "skill"]
}
```

**Note:** Skill auto-discovered from skills/ directory. No hooks. No commands in this example.

### Hybrid Plugin (Enforcement + Capability + Commands)

**Characteristics:**

- Has hooks/ directory
- Has skills/ directory
- Has commands/ directory

**Manifest:**

```json
{
  "name": "github-cli",
  "version": "2.0.0",
  "description": "GitHub CLI companion: security guard + comprehensive usage skill",
  "author": {
    "name": "and3r817",
    "url": "https://github.com/and3r817"
  },
  "license": "MIT",
  "keywords": ["github", "gh", "cli", "security", "skill", "hybrid"],
  "commands": [
    "./commands/gh-cli-status.md"
  ]
}
```

**Note:** Hooks auto-loaded. Skill auto-discovered. Commands explicitly listed.

## Agent Decision Tree: Manifest Creation

**Start:**

```
1. Create minimal manifest (name + description)
2. Validate syntax
3. Test plugin loads
```

**Expand:**

```
Plugin type:
├─ Hook only → No commands field
├─ Skill only → No commands field (unless commands/ exists)
└─ Hybrid → Add commands field if commands/ exists

Add metadata:
├─ version: "1.0.0"
├─ author: { name: "and3r817", url: "..." }
├─ license: "MIT"
└─ keywords: [based on type and technology]
```

**Validate:**

```
1. python3 -m json.tool plugin.json
2. Check no "skills" or "hooks" fields
3. Check commands field only if commands/ exists
4. Verify name format (lowercase-with-hyphens)
```

## Troubleshooting Decision Trees

### Issue: Plugin Not Loading

**Investigation:**

```
Plugin not appearing in /plugin list?
├─ JSON valid?
│  └─ python3 -m json.tool .claude-plugin/plugin.json
│
├─ File at correct path?
│  └─ ls .claude-plugin/plugin.json
│
├─ Name field valid?
│  └─ Check lowercase-with-hyphens format
│
└─ Description field present?
   └─ Check not empty
```

### Issue: Commands Not Appearing

**Investigation:**

```
Commands not showing in /slash list?
├─ Commands listed in manifest?
│  └─ Check "commands": ["./commands/cmd.md"]
│
├─ File exists?
│  └─ ls commands/cmd.md
│
├─ Path uses forward slashes?
│  └─ Check not .\\commands\\cmd.md
│
└─ Frontmatter valid?
   └─ Read commands/cmd.md, check --- delimiters
```

### Issue: Skills Not Loading

**Investigation:**

```
Skills not activating?
├─ Skill NOT in manifest?
│  └─ SHOULD be auto-discovered, remove if listed
│
├─ File in correct location?
│  └─ ls skills/skill-name/SKILL.md
│
├─ Frontmatter valid?
│  └─ Check name, description, allowed-tools
│
└─ Description includes trigger keywords?
   └─ Update description with user query terms
```

## Agent Implementation Checklist

**When writing plugin.json:**

- [ ] Start with minimal version (name + description)
- [ ] Validate JSON syntax immediately
- [ ] Verify name uses lowercase-with-hyphens
- [ ] Description is specific and actionable
- [ ] DO NOT include "skills" field
- [ ] DO NOT include "hooks" field
- [ ] Only include "commands" if commands/ exists
- [ ] Use forward slashes in all paths
- [ ] Expand to production version after testing
- [ ] Add version, author, license, keywords
- [ ] Validate final JSON syntax

## Best Practices

### Do's ✅

**Content:**

- Use semantic versioning for version field
- Provide clear, specific descriptions
- Include author information for attribution
- Add relevant keywords for discovery

**Format:**

- Validate JSON syntax before committing
- Use forward slashes in all paths
- Keep descriptions under 200 characters

**Structure:**

- Start minimal, expand after validation
- Only include commands if commands/ exists
- Never list skills or hooks

### Don'ts ❌

**Content:**

- Don't use vague descriptions ("A plugin")
- Don't use spaces or special characters in name
- Don't skip required fields (name, description)

**Format:**

- Don't include trailing commas
- Don't use Windows-style paths (backslashes)
- Don't use tabs in JSON (spaces only)

**Structure:**

- Don't list skills in manifest (auto-discovered)
- Don't list hooks.json in manifest (auto-loaded)
- Don't list tests, references, assets, scripts

## See Also

- [Plugin Architecture](./plugin-architecture.md) — Component structure and auto-discovery
- [Hook Configuration Format](./hook-configuration.md) — hooks.json reference
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
