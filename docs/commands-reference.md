# Slash Commands Reference

**Agent Context**: Read when implementing or validating slash commands. Quick reference for command file structure.

## When to Consult This Document

**READ when:**

- Implementing new slash command for plugin
- Validating command frontmatter syntax
- Understanding bash_permissions configuration
- Debugging command not appearing in /slash list

**SKIP when:**

- You already know minimal command structure
- Working on hooks or skills (not commands)
- Only need to validate YAML syntax

## Location

**Standard path**: `commands/<command-name>.md`

**Reference in plugin.json**: Required if commands exist

```json
{
  "commands": [
    "./commands/my-command.md"
  ]
}
```

## Minimal Required Command

**Start with this:**

```markdown
---
description: One-line description of what command does
---

# Command Name

## Usage

/command-name [arguments]

## Implementation

1. Action step 1
2. Action step 2
```

**Agent Implementation:**

1. Copy minimal pattern above
2. Replace description (MUST be actionable, <100 chars)
3. Replace command name
4. Add implementation steps
5. Test: Restart Claude Code, verify command appears in /slash

## Frontmatter Fields Reference

### Required Fields

#### description

**Type:** String
**Max length:** 200 characters (recommend <100)

**Validation Rules:**

- MUST be actionable (what command does, not what it is)
- MUST be concise (shown in /slash list)
- Use active voice

**Valid:**

```yaml
description: Deploy application to production environment
description: Run test suite and generate coverage report
```

**Invalid:**

```yaml
description: A command  # ❌ Too vague
description: This command deploys the application to production and runs post-deployment checks and validates health endpoints and sends notifications  # ❌ Too long
```

### Optional Fields

#### argument-hint

**Type:** String

**Purpose:** Show expected arguments in autocomplete

```yaml
argument-hint: [message]
argument-hint: [environment] [--force]
argument-hint: <file-path>
```

**Agent Usage:** Helps users understand what arguments the command expects.

#### model

**Type:** String

**Purpose:** Override the default model for this command

```yaml
model: claude-opus-4-5-20251101
model: claude-sonnet-4-20250514
```

**Agent Usage:** Use when command requires specific model capabilities (e.g., complex reasoning).

#### disable-model-invocation

**Type:** Boolean

**Purpose:** Prevent SlashCommand tool from invoking this command automatically

```yaml
disable-model-invocation: true
```

**Agent Usage:** Set `true` for commands that should only be user-invoked, not model-invoked.

#### allowed-tools

**Type:** Array of strings

**Purpose:** Restrict which tools command can use during execution

```yaml
allowed-tools:
  - Read
  - Bash(git:*)
  - Bash(docker:*)
  - Write
```

**Agent Selection Guidelines:**

- List ONLY tools command actually needs
- Use command-specific Bash syntax: `Bash(git:*)` not `Bash`
- Common patterns:
    - File operations: `Read`, `Write`, `Edit`
    - Search: `Grep`, `Glob`
    - Execution: `Bash(cmd:*)`

**Tool Syntax:**

```yaml
Bash(git:*)      # Only git commands
Bash(npm:*)      # Only npm commands
Bash(docker:*)   # Only docker commands
Bash             # All bash commands (use sparingly)
```

#### bash_permissions

**Type:** Array of strings

**Purpose:** Pre-approve bash commands for this command's execution

```yaml
bash_permissions:
  - git
  - docker
  - kubectl
  - npm
```

**Agent Rules:**

- List base commands (e.g., `git` not `git status`)
- Grants permission for command and all subcommands
- Does NOT restrict to only these commands
- Use when command executes known bash operations

**Example:**

```yaml
bash_permissions:
  - git        # Allows git status, git commit, git push, etc.
  - pytest     # Allows pytest -v, pytest --cov, etc.
```

## Argument Handling

### Variable Substitution

Commands can access user arguments via special variables:

| Variable     | Description                    | Example Input  | Result    |
|--------------|--------------------------------|----------------|-----------|
| `$ARGUMENTS` | All arguments as single string | `/cmd foo bar` | `foo bar` |
| `$1`         | First positional argument      | `/cmd foo bar` | `foo`     |
| `$2`         | Second positional argument     | `/cmd foo bar` | `bar`     |
| `$3`         | Third positional argument      | `/cmd a b c`   | `c`       |

**Example command using arguments:**

```markdown
---
description: Create a git commit with message
argument-hint: [message]
allowed-tools:
  - Bash(git:*)
---

Create a git commit with this message: $ARGUMENTS

If no message provided, ask user for commit message.
```

### Inline Bash Execution

Use `!` prefix for inline bash commands within the command prompt:

```markdown
---
description: Show project status
allowed-tools:
  - Bash(git:*)
  - Bash(npm:*)
---

# Project Status

Show the following information:
1. Git status: !git status --short
2. Current branch: !git branch --show-current
3. NPM outdated: !npm outdated
```

**Agent Rules:**

- `!` prefix requires corresponding `allowed-tools` entry
- Bash output is included in command context
- Use for gathering information before processing

### File References

Use `@` prefix to include file contents in command context:

```markdown
---
description: Review a specific file
allowed-tools:
  - Read
---

Review the following file for issues:
@$1

Focus on:
- Code quality
- Potential bugs
- Performance issues
```

**Usage:** `/review @src/utils.js` includes file contents in context.

**Agent Rules:**

- `@` prefix reads file contents into command prompt
- Requires `Read` in allowed-tools
- Can combine with positional arguments: `@$1`

## Command Structure Patterns

### Pattern 1: Simple Action Command

**Use when:** Single-purpose command executing predefined steps

```markdown
---
description: Show git status and recent commits
allowed-tools:
  - Bash(git:*)
---

# Git Summary

## Usage

/git-summary

## Implementation

1. Run `git status` to show working tree state
2. Run `git log --oneline -10` to show recent commits
3. Display results to user
```

**Agent Implementation:** Straightforward execution, no complex logic.

### Pattern 2: Command with Arguments

**Use when:** Command accepts user parameters

```markdown
---
description: Deploy to specified environment
allowed-tools:
  - Bash(git:*)
  - Bash(docker:*)
  - Bash(kubectl:*)
---

# Deploy

## Usage

/deploy [environment]

**Arguments:**

- `environment` - Target environment (dev, staging, prod)

## Implementation

1. Validate environment argument
2. Build Docker image
3. Deploy to Kubernetes cluster for specified environment
4. Verify deployment health
```

**Agent Implementation:** Parse arguments from user input, validate before execution.

### Pattern 3: Interactive Command

**Use when:** Command requires user decisions during execution

```markdown
---
description: Interactive code review with suggestions
allowed-tools:
  - Read
  - Grep
  - AskUserQuestion
---

# Code Review

## Usage

/code-review [file-pattern]

## Implementation

1. Find files matching pattern
2. Analyze code for issues
3. For each issue:
    - Present issue to user
    - Ask if user wants fix applied
    - Apply fix if approved
4. Summarize changes
```

**Agent Implementation:** Use AskUserQuestion tool for decisions during execution.

### Pattern 4: Research Command

**Use when:** Command gathers information without modifications

```markdown
---
description: Research API design patterns in codebase
allowed-tools:
  - Grep
  - Glob
  - Read
  - WebSearch
---

# API Research

## Usage

/api-research [topic]

## Implementation

1. Search codebase for existing patterns
2. Search web for best practices
3. Analyze findings
4. Present recommendations with examples
```

**Agent Implementation:** Read-only investigation, no file modifications.

## Validation

### YAML Frontmatter Check

```bash
# Extract and validate frontmatter
python3 -c "
import yaml
with open('commands/my-command.md') as f:
    content = f.read()
    if content.startswith('---'):
        frontmatter = content.split('---')[1]
        yaml.safe_load(frontmatter)
        print('Valid')
"
```

**Agent Action:** Run after writing command file.

### Common Frontmatter Errors

**Tabs instead of spaces:**

```yaml
description: Test
allowed-tools:
  →   - Read  # ❌ Tab character
```

**Fix:** Use spaces only

```yaml
description: Test
allowed-tools:
  - Read  # ✅ Spaces
```

**Missing quotes on special characters:**

```yaml
description:
  Deploy: production  # ❌ Colon breaks YAML
```

**Fix:** Quote strings with special characters

```yaml
description: "Deploy: production"  # ✅ Quoted
```

**Invalid list syntax:**

```yaml
allowed-tools: Read, Bash  # ❌ Not YAML list
```

**Fix:** Use proper list format

```yaml
allowed-tools:
  - Read
  - Bash
```

## Command Content Patterns

### Implementation Section

**Agent Requirements:**

- Use numbered steps (clear execution order)
- Be specific about what to do, not how to do it
- Reference tools explicitly if allowed-tools is restrictive

**Good:**

```markdown
## Implementation

1. Read package.json to identify dependencies
2. Run `npm audit` to check for vulnerabilities
3. Present findings with severity levels
4. If high-severity found, ask user if fixes should be applied
```

**Bad:**

```markdown
## Implementation

- Check dependencies
- Look for issues
- Fix if needed
```

### Usage Section

**Agent Requirements:**

- Show exact command syntax
- Document all arguments
- Provide examples if multiple usage patterns

**Good:**

```markdown
## Usage

/deploy [environment] [--force]

**Arguments:**

- `environment` - Target: dev, staging, prod
- `--force` - Skip confirmation prompts

**Examples:**
/deploy prod
/deploy staging --force
```

**Bad:**

```markdown
## Usage

Use /deploy with environment name
```

### Examples Section (Optional)

**When to include:** Multiple usage patterns or complex arguments

```markdown
## Examples

**Basic deployment:**
/deploy staging

**Force deployment without prompts:**
/deploy prod --force

**Deploy specific version:**
/deploy prod --version=v2.1.0
```

## Agent Decision Tree: Command Creation

**Start:**

```
1. Create commands/command-name.md
2. Write minimal frontmatter (description required)
3. Validate YAML syntax
4. Test command loads (/slash list in Claude Code)
```

**Expand:**

```
Command needs bash execution?
├─ YES → Add bash_permissions field
│         List base commands (git, docker, npm, etc.)
│
└─ NO → Check if needs other tools
          Add allowed-tools if command should be restricted
```

**Validate:**

```
1. YAML syntax valid (python yaml.safe_load)
2. Description is actionable and concise
3. Implementation steps are clear and ordered
4. Command appears in /slash list
```

## Troubleshooting Decision Trees

### Issue: Command Not Appearing

**Investigation:**

```
Command not in /slash list?
├─ Listed in plugin.json?
│  └─ Check "commands": ["./commands/cmd.md"]
│
├─ File exists?
│  └─ ls commands/cmd.md
│
├─ Frontmatter valid?
│  └─ Check YAML syntax (see validation above)
│
├─ Description present?
│  └─ description: "..." must exist
│
└─ Plugin installed?
   └─ /plugin list shows plugin name
```

### Issue: Command Execution Fails

**Investigation:**

```
Command fails during execution?
├─ Tool access denied?
│  └─ Check allowed-tools includes required tools
│
├─ Bash permission denied?
│  └─ Check bash_permissions includes command
│
├─ Implementation steps clear?
│  └─ Verify numbered steps are specific
│
└─ Arguments parsed correctly?
   └─ Check Usage section documents args correctly
```

## Integration with Plugin Manifest

**Agent Action:** After creating command file, add to plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "commands": [
    "./commands/deploy.md",
    "./commands/test.md",
    "./commands/status.md"
  ]
}
```

**Validation:**

```bash
# Verify all command paths exist
python3 -m json.tool .claude-plugin/plugin.json
for cmd in $(jq -r '.commands[]' .claude-plugin/plugin.json); do
  ls "$cmd" || echo "Missing: $cmd"
done
```

## Agent Implementation Checklist

**Before creating command:**

- [ ] Understand command purpose (action vs research vs interactive)
- [ ] Determine required tools
- [ ] Identify bash commands needed (if any)

**During creation:**

- [ ] Create commands/command-name.md
- [ ] Write minimal frontmatter (description required)
- [ ] Add allowed-tools if command should be restricted
- [ ] Add bash_permissions if bash execution needed
- [ ] Write clear numbered implementation steps
- [ ] Document usage with arguments

**After creation:**

- [ ] Validate YAML syntax
- [ ] Add to plugin.json commands array
- [ ] Validate plugin.json syntax
- [ ] Test in Claude Code (/slash list)
- [ ] Test command execution

## Best Practices

### Do's ✅

**Frontmatter:**

- Use actionable descriptions (<100 chars)
- List only required tools in allowed-tools
- Use command-specific Bash syntax: `Bash(git:*)`
- Validate YAML after every edit

**Content:**

- Number implementation steps clearly
- Document all arguments in Usage section
- Provide examples for complex commands
- Keep command focused (single responsibility)

**Structure:**

- Use forward slashes in plugin.json paths
- Keep command files under 200 lines
- Separate complex logic into helper scripts

### Don'ts ❌

**Frontmatter:**

- Don't use vague descriptions ("A command")
- Don't grant broad Bash access unless necessary
- Don't use tabs in YAML (spaces only)
- Don't skip description field

**Content:**

- Don't use unnumbered steps (hard to follow)
- Don't assume user knows arguments
- Don't make commands do too many unrelated things

**Structure:**

- Don't use absolute paths
- Don't use Windows-style paths (backslashes)
- Don't forget to add command to plugin.json

## See Also

- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json reference for commands field
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
- [Skills Reference](./skills-reference.md) — Agent Skills vs Commands comparison
