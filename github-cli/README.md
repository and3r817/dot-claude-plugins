# GitHub CLI

Comprehensive GitHub CLI (`gh`) companion providing both security protection and usage guidance.

## What It Does

**🛡️ Security Guard** - Blocks write operations by default (POST, PUT, PATCH, DELETE)
**📚 Usage Skill** - Comprehensive gh CLI guidance for automation, API access, and workflows

## Install

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install github-cli@dot-claude-plugins
```

## Features

### 1. Security Guard (Hook)

Protects against unintended write operations by blocking:

- Repository modifications: `gh repo delete`, `gh repo create`, `gh repo archive`
- PR/Issue changes: `gh pr merge`, `gh pr create`, `gh issue close`
- API write methods: `gh api -X POST`, `gh api -X PUT/PATCH/DELETE`
- Workflow operations: `gh workflow run`, `gh run cancel`
- Implicit POST via field parameters: `gh api endpoint -f param=value`

**Allowed operations:**
- All read commands: `gh repo view`, `gh pr list`, `gh issue list`
- API GET requests: `gh api repos/{owner}/{repo}`
- Search operations: `gh search prs`, `gh search issues`

**Blocked examples:**
```bash
gh repo delete owner/repo          # ❌ Blocked
gh pr merge 123                    # ❌ Blocked
gh api -X POST /repos/.../issues   # ❌ Blocked
```

**Allowed examples:**
```bash
gh repo view owner/repo            # ✅ Allowed
gh pr list                         # ✅ Allowed
gh api repos/{owner}/{repo}        # ✅ Allowed (GET)
```

### 2. Usage Skill (SKILL.md)

Automatically provides guidance when working with GitHub CLI:

- **Authentication & Setup** - `gh auth login`, token management
- **Repository Management** - Creating, cloning, forking repositories
- **PR Workflow** - Creating, reviewing, merging pull requests
- **Issue Management** - Creating, listing, managing issues
- **API Access** - REST (v3) and GraphQL (v4) patterns
- **GitHub Actions** - Workflow and run management
- **Scripting & Automation** - Shell patterns, CI/CD integration
- **Search Operations** - Finding PRs, issues, code, repositories

**Triggers automatically when:**
- User mentions "gh", "github cli", or GitHub operations
- Working with repositories, PRs, issues, releases
- Querying GitHub API
- Automating GitHub workflows

**Example usage:**
```
User: "Create a pull request for this branch"
Claude: [Uses skill to guide on gh pr create with appropriate flags]

User: "Query the GitHub API to get repository statistics"
Claude: [Provides gh api examples with REST/GraphQL patterns]
```

## Commands

- `/gh-cli-status` - View current guard status and blocked attempts
- `/gh-cli-enable` - Enable write protection (default)
- `/gh-cli-disable` - Temporarily disable write protection

## Authorization Workflow

When write operations are needed:

1. **Claude asks for permission** before attempting write operations
2. User runs `/gh-cli-disable` to temporarily disable guard
3. Claude performs authorized write operations
4. User runs `/gh-cli-enable` to re-enable protection

## Configuration

`~/.claude/settings.json`:

```json
{
  "githubCli": {
    "enabled": true,
    "allowedWriteCommands": [],
    "logBlockedAttempts": true,
    "notifyOnBlock": false,
    "logPath": "~/.claude/logs/gh-cli.log"
  }
}
```

**Options:**
- `enabled` - Enable/disable write guard (default: true)
- `allowedWriteCommands` - Whitelist specific write commands
- `logBlockedAttempts` - Log blocked attempts to file
- `notifyOnBlock` - Show notification when command blocked
- `logPath` - Location of log file

## Plugin Structure

```
github-cli/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   ├── hooks.json            # PreToolUse hook configuration
│   └── gh_write_blocker.py   # Security guard implementation
├── scripts/
│   └── gh_write_blocker.py   # Hook script
├── commands/
│   ├── gh-cli-status.md      # Status command
│   ├── gh-cli-enable.md      # Enable guard command
│   └── gh-cli-disable.md     # Disable guard command
├── references/               # Reference documentation
│   ├── gh-commands.md        # Complete command catalog
│   ├── gh-api-patterns.md    # REST/GraphQL API patterns
│   └── gh-scripting.md       # Automation & scripting guides
├── tests/
│   └── test-gh-write-blocker.sh  # Test suite
├── SKILL.md                  # Usage skill with gh patterns
└── README.md                 # This file
```

## How It Works

### Security Hook

The PreToolUse hook intercepts all `Bash` tool commands before execution:

1. Checks if command starts with `gh `
2. Validates command against write operation patterns
3. Blocks write operations (exit 2) or allows read operations (exit 0)
4. Provides helpful error messages with alternatives

**Detection logic:**
- HTTP method flags: `-X POST`, `--method PUT`, etc.
- Field parameters: `-f`, `-F`, `--field` (implicit POST)
- Write commands: `gh pr merge`, `gh repo delete`, etc.
- Case-insensitive method checking for security

### Usage Skill

The skill provides context-aware guidance:

1. Loads automatically when gh CLI operations are mentioned
2. References comprehensive documentation in `references/`
3. Provides examples and best practices
4. Explains security considerations
5. Shows both basic and advanced patterns

## Examples

### Creating a Pull Request (Guided)

```
User: "Create a pull request for my feature branch"

Claude: I'll help you create a pull request. Since this is a write
operation, I need your permission first.

To create a PR, you can use:
  gh pr create --title "Feature: X" --body "Description"
  gh pr create --draft  # Create as draft first

Would you like me to create the PR? If so, please run /gh-cli-disable first.
```

### Querying GitHub API (Automatic)

```
User: "Get the star count for this repository"

Claude: [Uses skill to provide gh api command]
  gh api repos/{owner}/{repo} --jq '.stargazers_count'

This is a read-only operation, so it's allowed by the security guard.
```

### Complex Automation (With References)

```
User: "Help me automate PR reviews with gh CLI"

Claude: [Loads gh-scripting.md reference]
Here's a script pattern for automated PR reviews:

[Provides complete script with rate limiting, error handling, etc.]
```

## Testing

Run the test suite:

```bash
./run-all-tests.sh
# or
./test-framework.sh github-cli/tests/test-gh-write-blocker.sh
```

Tests cover:
- Allow non-gh commands
- Allow gh read commands
- Block gh write commands
- Block gh api write methods
- Block implicit POST via field parameters
- Handle edge cases (empty input, false positives)
- Case-insensitive method detection

## Documentation References

- [Complete Command Catalog](references/gh-commands.md) - All gh commands by category
- [API Patterns](references/gh-api-patterns.md) - REST/GraphQL examples
- [Scripting Guide](references/gh-scripting.md) - Automation patterns

Official Resources:
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub Docs](https://docs.github.com/en/github-cli)
- [Scripting with gh](https://github.blog/engineering/engineering-principles/scripting-with-github-cli/)

## Uninstall

```bash
/plugin uninstall github-cli
```
