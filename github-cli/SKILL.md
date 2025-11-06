---
name: github-cli
description: This skill should be used when working with GitHub CLI (gh) for repository management, pull requests, issues, API access, GitHub Actions, or automation workflows. Provides comprehensive guidance on gh command patterns, security considerations, and best practices.
---

# GitHub CLI (gh) Usage Skill

## Purpose

GitHub CLI (`gh`) is the official command-line interface to GitHub, enabling direct interaction with repositories, pull requests, issues, GitHub Actions, and the GitHub API without leaving the terminal. This skill provides systematic guidance for using gh effectively while maintaining security through the integrated write-guard protection.

## When to Use This Skill

Invoke this skill when:
- Creating or managing pull requests and issues via command line
- Querying GitHub API (REST or GraphQL) for repository data
- Automating GitHub workflows and Actions
- Managing releases, gists, projects, or codespaces
- Scripting GitHub operations for CI/CD pipelines
- User explicitly mentions "gh", "github cli", or requests GitHub interactions

## Core Concepts

### Authentication First

Before any gh operations, verify authentication status:

```bash
gh auth status              # Check current authentication
gh auth login               # Interactive authentication setup
gh auth refresh             # Refresh expired tokens
```

Authentication automatically stores Git credentials when HTTPS is selected as the preferred protocol.

### gh vs git Distinction

- **`git`**: Version control operations (commit, push, pull) - works with any remote service
- **`gh`**: GitHub-specific operations (PRs, issues, API, Actions) - GitHub only

Use `gh` for GitHub platform interactions; use `git` for repository version control.

## Command Categories & Patterns

### Repository Management

```bash
gh repo view OWNER/REPO           # View repository details and README
gh repo view --web                # Open repository in browser
gh repo clone OWNER/REPO          # Clone repository locally
gh repo list OWNER --limit 100    # List organization repositories
gh repo fork                      # Fork current repository
```

### Pull Request Workflow

```bash
# Create
gh pr create --draft --title "Feature: X" --body "Description"
gh pr create --base main --head feature-branch

# List & Filter
gh pr list                        # List PRs in current repo
gh pr list --author "@me"         # PRs authored by authenticated user
gh pr list --assignee "@me"       # PRs assigned to authenticated user
gh pr list --label "bug"          # Filter by label

# View & Checkout
gh pr view 123                    # View PR details
gh pr view 123 --web              # Open in browser
gh pr checkout 123                # Check out PR branch locally
gh pr diff 123                    # View PR diff

# Review & Checks
gh pr review 123 --approve        # Approve PR
gh pr review 123 --comment --body "LGTM"
gh pr checks                      # View status checks

# Merge (⚠️ Write operation - requires guard disable)
gh pr merge 123 --squash          # Squash and merge
gh pr merge 123 --rebase          # Rebase and merge
```

### Issue Management

```bash
# Create
gh issue create --title "Bug: X" --body "Description" --label "bug"

# List & Filter
gh issue list                     # List all issues
gh issue list --assignee "@me"    # Assigned to authenticated user
gh issue list --label "priority"  # Filter by label
gh issue list --state closed      # Show closed issues

# View & Comment
gh issue view 456                 # View issue details
gh issue comment 456 --body "Update"

# Modify (⚠️ Write operations - require guard disable)
gh issue close 456
gh issue edit 456 --add-label "duplicate"
```

### GitHub API Access

The `gh api` command provides authenticated access to GitHub's REST (v3) and GraphQL (v4) APIs with automatic placeholder substitution for `{owner}`, `{repo}`, and `{branch}`.

#### REST API Patterns

```bash
# GET (read-only, default method)
gh api repos/{owner}/{repo}/releases
gh api /repos/OWNER/REPO/issues
gh api -X GET repos/{owner}/{repo}/branches

# GET with parameters (explicit method required)
gh api -X GET repos/{owner}/{repo}/issues -f state=closed -f labels=bug

# Pagination
gh api --paginate repos/{owner}/{repo}/issues

# JSON filtering with jq
gh api repos/{owner}/{repo} --jq '.stargazers_count'
gh api repos/{owner}/{repo}/pulls --jq '.[].title'

# Caching
gh api --cache 1h repos/{owner}/{repo}/releases
```

#### GraphQL Patterns

```bash
# Basic query
gh api graphql -f query='
  query {
    viewer {
      login
      name
    }
  }
'

# Pagination with variables
gh api graphql --paginate -f query='
  query($endCursor: String) {
    repository(owner: "OWNER", name: "REPO") {
      issues(first: 100, after: $endCursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          title
          number
        }
      }
    }
  }
'
```

#### ⚠️ API Write Operations

POST, PUT, PATCH, DELETE methods are **blocked by default** via the security guard:

```bash
# ❌ Blocked - Write operation
gh api -X POST repos/{owner}/{repo}/issues -f title="New Issue"

# ✅ Requires explicit permission or /gh-cli-disable
# User must authorize write operations first
```

Field parameters (`-f`, `-F`, `--field`) trigger implicit POST unless `-X GET` is specified:

```bash
# ❌ Blocked - Implicit POST
gh api repos/{owner}/{repo}/issues -f title="Bug"

# ✅ Allowed - Explicit GET
gh api -X GET repos/{owner}/{repo}/issues -f state=open
```

### GitHub Actions & Workflows

```bash
# List workflows
gh workflow list

# Run workflow (⚠️ Write operation)
gh workflow run ci.yml
gh workflow run ci.yml -f environment=production

# View runs
gh run list --workflow=ci.yml
gh run view 123456789
gh run view --log-failed          # Show failed logs
gh run watch                      # Watch current run

# Manage runs (⚠️ Write operations)
gh run cancel 123456789
gh run rerun 123456789
```

### Releases

```bash
# List releases
gh release list
gh release view v1.0.0

# Download assets
gh release download v1.0.0

# Create release (⚠️ Write operation)
gh release create v1.0.0 --title "Release 1.0.0" --notes "Features..."
gh release create v1.0.0 ./dist/*.tar.gz --generate-notes
```

### Search Operations

```bash
# Search PRs
gh search prs --review-requested=@me --state=open
gh search prs "is:pr is:open author:USERNAME"

# Search issues
gh search issues "is:issue is:open label:bug"

# Search code
gh search code "function calculateTotal"

# Search repositories
gh search repos "topic:machine-learning language:python"
```

## Scripting & Automation

### Output Formatting

gh automatically formats output for machine readability when piped:

```bash
# Human-readable (colored, formatted)
gh pr list

# Machine-readable (tab-delimited, no colors)
gh pr list | cut -f1        # Extract PR numbers
gh pr list --json number,title --jq '.[] | "\(.number): \(.title)"'
```

### JSON Output & jq Integration

```bash
# Export as JSON
gh pr list --json number,title,author,state

# Filter with jq
gh repo list --json name,description --jq '.[] | select(.description != null)'

# Transform data
gh api repos/{owner}/{repo}/contributors --jq '[.[] | {name: .login, commits: .contributions}]'
```

### Aliases for Common Operations

```bash
# Create aliases
gh alias set prd "pr create --draft"
gh alias set pv "pr view --web"
gh alias set il "issue list --assignee @me"

# Use aliases
gh prd --title "WIP: Feature"
gh pv 123
```

### Composition with Unix Tools

```bash
# Interactive PR selection with fzf
gh pr list | fzf | cut -f1 | xargs gh pr checkout

# Bulk operations
gh issue list --json number --jq '.[].number' | xargs -I {} gh issue close {}

# Conditional logic
gh pr checks && gh pr merge --auto || echo "Checks failed"
```

## Security Considerations

### Write Protection

This plugin includes a **security guard** that blocks write operations by default:

**Blocked operations:**
- Repository modifications: `gh repo create`, `gh repo delete`, `gh repo archive`
- PR/Issue changes: `gh pr create`, `gh pr merge`, `gh issue close`, `gh issue edit`
- Release management: `gh release create`, `gh release delete`
- API write methods: `gh api -X POST`, `gh api -X PUT`, `gh api -X PATCH`, `gh api -X DELETE`
- Workflow triggers: `gh workflow run`, `gh run cancel`

**Allowed operations:**
- All read commands: `gh repo view`, `gh pr list`, `gh issue list`
- API GET requests: `gh api repos/{owner}/{repo}`
- Search operations: `gh search prs`, `gh search issues`

### Authorization Workflow

When write operations are needed:

1. **Ask user for explicit permission first**
2. User runs `/gh-cli-disable` to temporarily disable guard
3. Perform authorized write operations
4. User runs `/gh-cli-enable` to re-enable protection

### API Method Security

```bash
# ❌ Blocked - Write methods
gh api -X POST /repos/{owner}/{repo}/issues
gh api -X PUT /repos/{owner}/{repo}
gh api -X DELETE /repos/{owner}/{repo}/issues/123

# ❌ Blocked - Implicit POST via field parameters
gh api /repos/{owner}/{repo}/issues -f title="Bug"

# ✅ Allowed - Explicit GET with parameters
gh api -X GET /repos/{owner}/{repo}/issues -f state=open -f labels=bug
```

## Common Patterns & Best Practices

### Interactive Repository Selection

```bash
# Select repo interactively
gh repo list | fzf | cut -f1 | xargs gh repo view
```

### Bulk PR Status Checks

```bash
# Check all open PRs
gh pr list --json number --jq '.[].number' | while read pr; do
  echo "PR #$pr:"
  gh pr checks $pr
done
```

### Release Automation

```bash
# Create release from CI/CD
VERSION="v$(cat VERSION)"
gh release create "$VERSION" \
  --title "Release $VERSION" \
  --generate-notes \
  ./dist/*
```

### Team Workflow

```bash
# Review queue
gh search prs --review-requested=@me --state=open

# Team PRs
gh pr list --author team-member

# Label-based workflows
gh issue list --label "needs-triage" --json number,title --jq '.[] | "\(.number): \(.title)"'
```

## References

For detailed command references and advanced patterns, see:
- `references/gh-commands.md` - Complete command catalog by category
- `references/gh-api-patterns.md` - REST/GraphQL examples and authentication
- `references/gh-scripting.md` - Automation patterns and best practices

## Configuration

### Settings Location

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

### Available Commands

- `/gh-cli-status` - View current guard status and blocked attempts
- `/gh-cli-enable` - Enable write protection (default)
- `/gh-cli-disable` - Temporarily disable write protection

## Environment Variables

```bash
# Override repository context
export GH_REPO="owner/repo"

# Use specific GitHub instance
export GH_HOST="github.example.com"

# Set API token directly (not recommended)
export GITHUB_TOKEN="ghp_..."

# Configure pager
export PAGER="less -FX"
```

## Troubleshooting

### Authentication Issues

```bash
gh auth status          # Check authentication state
gh auth refresh         # Refresh expired token
gh auth logout          # Clear credentials
gh auth login           # Re-authenticate
```

### API Rate Limits

```bash
# Check rate limit
gh api rate_limit

# Use caching to reduce requests
gh api --cache 1h repos/{owner}/{repo}/releases
```

### Debug Mode

```bash
# Verbose output
gh pr create --title "Test" --verbose

# See HTTP requests
GH_DEBUG=api gh api repos/{owner}/{repo}
```

## Official Documentation

- GitHub CLI Manual: https://cli.github.com/manual/
- GitHub Docs: https://docs.github.com/en/github-cli
- Repository: https://github.com/cli/cli
- Scripting Guide: https://github.blog/engineering/engineering-principles/scripting-with-github-cli/
