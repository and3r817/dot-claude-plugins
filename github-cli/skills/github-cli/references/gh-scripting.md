# GitHub CLI Scripting & Automation Patterns

Comprehensive guide to automating GitHub workflows with gh CLI, including shell scripting patterns, CI/CD integration,
and advanced automation techniques.

## Table of Contents

1. [Scripting Fundamentals](#scripting-fundamentals)
2. [Output Formats](#output-formats)
3. [Tool Composition](#tool-composition)
4. [Aliases & Configuration](#aliases--configuration)
5. [CI/CD Integration](#cicd-integration)
6. [Common Workflows](#common-workflows)
7. [Advanced Patterns](#advanced-patterns)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)

## Scripting Fundamentals

### Environment Variables

```bash
# Repository context
export GH_REPO="owner/repo"           # Default repository
export GH_HOST="github.com"           # GitHub instance

# Authentication
export GITHUB_TOKEN="ghp_xxxx"        # API token
export GH_TOKEN="ghp_xxxx"            # Alternative

# Output control
export GH_PAGER=""                    # Disable pager for scripts
export PAGER="cat"                    # Use cat as pager
export NO_COLOR=1                     # Disable colors

# Debug
export GH_DEBUG=api                   # Debug API calls
```

### Exit Codes

```bash
# Success
gh pr view 123 && echo "PR exists"    # Exit 0

# Failure
gh pr view 999 || echo "PR not found" # Exit non-zero

# Check specific codes
gh pr view 123
case $? in
  0) echo "Success" ;;
  1) echo "General error" ;;
  2) echo "Authentication error" ;;
  4) echo "Not found" ;;
esac
```

### Shebang & Set Options

```bash
#!/usr/bin/env bash
set -euo pipefail                     # Strict mode
# -e: exit on error
# -u: exit on undefined variable
# -o pipefail: exit on pipe failure

# Optional: trace execution
set -x
```

## Output Formats

### Human-Readable vs Machine-Readable

gh automatically detects when output is piped and switches to tab-delimited format:

```bash
# Human-readable (terminal)
gh pr list
# Colored, formatted table

# Machine-readable (piped)
gh pr list | cat
# Tab-delimited, no colors
```

### Tab-Delimited Output

```bash
# Extract fields with cut
gh pr list | cut -f1              # PR numbers
gh pr list | cut -f1,2            # Numbers and titles
gh pr list | cut -f1-3            # First three fields

# Field order (typical):
# 1: Number/ID
# 2: Title/Name
# 3: Branch/State
# 4: Author/Updated
```

### JSON Output

```bash
# Output as JSON
gh pr list --json number,title,state

# With jq filtering
gh pr list --json number,title,author --jq '.[] | "\(.number): \(.title)"'

# Available fields (use --json help)
gh pr list --json help
```

### Custom Formatting with Templates

```bash
# Go template
gh pr list --template '{{range .}}{{.number}}: {{.title}}{{"\n"}}{{end}}'

# Template from file
gh pr list --template "$(cat template.tmpl)"
```

## Tool Composition

### Pipe to Standard Unix Tools

```bash
# Count items
gh pr list | wc -l

# Search in output
gh pr list | grep "bug"

# Sort by field
gh issue list | sort -k2          # Sort by title

# Unique values
gh pr list | cut -f4 | sort | uniq  # Unique authors

# Head/tail
gh pr list | head -n 10           # First 10 PRs
gh issue list | tail -n 5         # Last 5 issues
```

### Integration with fzf (Fuzzy Finder)

```bash
# Interactive PR selection
gh pr list | fzf

# Checkout selected PR
gh pr list | fzf | cut -f1 | xargs gh pr checkout

# View selected issue
gh issue list | fzf | cut -f1 | xargs gh issue view

# Create alias for common pattern
alias ghprc='gh pr list | fzf | cut -f1 | xargs gh pr checkout'
```

### Integration with jq (JSON Processor)

```bash
# Extract specific fields
gh pr list --json number,title --jq '.[].number'

# Filter by condition
gh pr list --json number,title,state --jq '.[] | select(.state == "OPEN")'

# Transform data
gh api repos/{owner}/{repo}/contributors --jq '[.[] | {
  username: .login,
  contributions: .contributions
}]'

# Aggregate
gh pr list --json number,createdAt --jq 'length'
```

### Integration with xargs (Batch Processing)

```bash
# Close multiple issues
echo "123 124 125" | xargs -n1 gh issue close

# Delete old branches
gh api repos/{owner}/{repo}/branches --jq '.[].name' | \
  grep "feature/" | \
  xargs -I {} gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/{}

# Parallel execution
gh issue list --json number --jq '.[].number' | \
  xargs -P 4 -I {} gh issue view {}
```

## Aliases & Configuration

### Creating Aliases

```bash
# PR shortcuts
gh alias set prc "pr create --draft"
gh alias set prl "pr list --author @me"
gh alias set prv "pr view --web"

# Issue shortcuts
gh alias set il "issue list --assignee @me"
gh alias set ic "issue create"

# Complex aliases with arguments
gh alias set review 'pr review --approve'

# Alias with multiple commands
gh alias set deploy '!gh pr merge && gh workflow run deploy.yml'
```

### Configuration Files

```bash
# View config file location
gh config get -h github.com oauth_token

# Set preferences
gh config set editor "code -w"
gh config set pager "less -FX"
gh config set git_protocol https
gh config set prompt enabled

# Disable paging for scripts
gh config set pager ""
```

### Import/Export Aliases

```bash
# Export aliases
gh alias list > aliases.txt

# Import aliases
gh alias import aliases.txt

# Share team aliases
cat << EOF > team-aliases.txt
co: pr checkout
bugs: issue list --label bug --assignee @me
EOF
gh alias import team-aliases.txt
```

## CI/CD Integration

### GitHub Actions

gh CLI is pre-installed in GitHub Actions:

```yaml
name: Auto-merge Dependabot PRs
on:
  pull_request:
    branches: [main]

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Enable auto-merge
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh pr merge --auto --squash "${{ github.event.pull_request.number }}"
```

### Release Automation

```yaml
name: Create Release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build artifacts
        run: make build

      - name: Create release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          gh release create "$VERSION" \
            --title "Release $VERSION" \
            --generate-notes \
            ./dist/*
```

### PR Status Checks

```yaml
name: PR Checks
on: pull_request

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - name: Check PR labels
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LABELS=$(gh pr view ${{ github.event.pull_request.number }} \
            --json labels --jq '.labels[].name')

          if ! echo "$LABELS" | grep -q "ready"; then
            echo "PR must have 'ready' label"
            exit 1
          fi
```

### Cross-Repository Operations

```yaml
name: Sync Docs
on:
  push:
    paths:
      - 'docs/**'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Create PR in docs repo
        env:
          GH_TOKEN: ${{ secrets.PAT_TOKEN }}  # Personal access token needed
        run: |
          gh repo clone org/docs-repo
          cd docs-repo
          # Copy changes
          cp -r ../docs/* ./content/
          git add .
          git commit -m "Sync docs from main repo"
          git push origin sync-branch
          gh pr create --title "Sync docs" --body "Auto-sync from main repo"
```

## Common Workflows

### PR Review Queue

```bash
#!/usr/bin/env bash
# review-queue.sh - Show PRs needing review

echo "=== PRs Waiting for Your Review ==="
gh search prs --review-requested=@me --state=open \
  --json number,title,repository \
  --jq '.[] | "[\(.repository.nameWithOwner)] #\(.number): \(.title)"'

echo ""
echo "=== Your PRs Waiting for Review ==="
gh pr list --author "@me" --json number,title,reviews \
  --jq '.[] | select(.reviews | length == 0) | "#\(.number): \(.title)"'
```

### Bulk Issue Management

```bash
#!/usr/bin/env bash
# close-stale-issues.sh - Close issues inactive for 30 days

DAYS=30
CUTOFF_DATE=$(date -d "$DAYS days ago" +%Y-%m-%d)

gh issue list --state open --json number,updatedAt \
  --jq ".[] | select(.updatedAt < \"$CUTOFF_DATE\") | .number" | \
while read issue; do
  echo "Closing stale issue #$issue"
  gh issue close "$issue" \
    --comment "Closing due to inactivity for $DAYS days"
done
```

### Release Notes Generation

```bash
#!/usr/bin/env bash
# generate-release-notes.sh - Create release with categorized notes

VERSION=$1
PREV_VERSION=$(gh release list --limit 1 --json tagName --jq '.[0].tagName')

echo "## What's Changed"
echo ""

# Features
echo "### ✨ Features"
gh pr list --state merged --json number,title,labels \
  --jq ".[] | select(.labels[].name == \"feature\") | \"- \(.title) (#\(.number))\"" \
  | head -n 50

# Bug fixes
echo ""
echo "### 🐛 Bug Fixes"
gh pr list --state merged --json number,title,labels \
  --jq ".[] | select(.labels[].name == \"bug\") | \"- \(.title) (#\(.number))\"" \
  | head -n 50

# Save to file
echo ""
echo "**Full Changelog**: https://github.com/{owner}/{repo}/compare/$PREV_VERSION...$VERSION"
```

### Team Activity Report

```bash
#!/usr/bin/env bash
# team-report.sh - Weekly team activity summary

WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d)

echo "=== Team Activity Report ==="
echo "Period: $WEEK_AGO to $(date +%Y-%m-%d)"
echo ""

# Get team members
gh api orgs/{org}/teams/{team}/members --jq '.[].login' | \
while read user; do
  echo "## $user"

  # PRs created
  CREATED=$(gh search prs --author "$user" --created ">$WEEK_AGO" --json number --jq 'length')
  echo "  - PRs created: $CREATED"

  # PRs merged
  MERGED=$(gh search prs --author "$user" --merged ">$WEEK_AGO" --json number --jq 'length')
  echo "  - PRs merged: $MERGED"

  # Reviews given
  REVIEWS=$(gh search prs --reviewed-by "$user" --json number --jq 'length')
  echo "  - Reviews given: $REVIEWS"

  echo ""
done
```

### Dependency Update Workflow

```bash
#!/usr/bin/env bash
# auto-approve-deps.sh - Auto-approve dependency update PRs

gh pr list --author "dependabot[bot]" --json number,title | \
  jq -r '.[] | "\(.number) \(.title)"' | \
while read num title; do
  echo "Reviewing PR #$num: $title"

  # Check if only lock files changed
  FILES=$(gh pr view "$num" --json files --jq '.files[].path')
  if echo "$FILES" | grep -qv "lock\|package-lock.json\|yarn.lock"; then
    echo "  ⚠️  Non-lock files changed, skipping"
    continue
  fi

  # Check if tests pass
  CONCLUSION=$(gh pr checks "$num" --json conclusion --jq '.[0].conclusion')
  if [ "$CONCLUSION" != "SUCCESS" ]; then
    echo "  ⚠️  Tests not passing, skipping"
    continue
  fi

  # Approve and enable auto-merge
  gh pr review "$num" --approve --body "LGTM - automated approval"
  gh pr merge --auto --squash "$num"
  echo "  ✅ Approved and enabled auto-merge"
done
```

### Interactive PR Workflow

```bash
#!/usr/bin/env bash
# pr-workflow.sh - Interactive PR management

# Select repository
REPO=$(gh repo list --json nameWithOwner --jq '.[].nameWithOwner' | fzf)
export GH_REPO="$REPO"

while true; do
  echo ""
  echo "=== PR Workflow: $REPO ==="
  echo "1. List open PRs"
  echo "2. Review a PR"
  echo "3. Checkout a PR"
  echo "4. Merge a PR"
  echo "5. Create new PR"
  echo "6. Switch repository"
  echo "q. Quit"
  echo ""
  read -p "Select option: " opt

  case $opt in
    1)
      gh pr list
      ;;
    2)
      PR=$(gh pr list | fzf | cut -f1)
      [ -n "$PR" ] && gh pr view "$PR" && gh pr diff "$PR"
      ;;
    3)
      PR=$(gh pr list | fzf | cut -f1)
      [ -n "$PR" ] && gh pr checkout "$PR"
      ;;
    4)
      PR=$(gh pr list | fzf | cut -f1)
      [ -n "$PR" ] && gh pr merge "$PR" --squash
      ;;
    5)
      gh pr create
      ;;
    6)
      REPO=$(gh repo list --json nameWithOwner --jq '.[].nameWithOwner' | fzf)
      export GH_REPO="$REPO"
      ;;
    q)
      exit 0
      ;;
  esac
done
```

## Advanced Patterns

### Rate Limit Monitoring

```bash
#!/usr/bin/env bash
# check-rate-limit.sh - Monitor and warn about rate limits

check_rate_limit() {
  LIMIT=$(gh api rate_limit --jq '.rate')
  REMAINING=$(echo "$LIMIT" | jq -r '.remaining')
  TOTAL=$(echo "$LIMIT" | jq -r '.limit')
  RESET=$(echo "$LIMIT" | jq -r '.reset')
  RESET_TIME=$(date -d "@$RESET" '+%Y-%m-%d %H:%M:%S')

  PERCENT=$((REMAINING * 100 / TOTAL))

  if [ "$PERCENT" -lt 10 ]; then
    echo "⚠️  WARNING: Rate limit critical: $REMAINING/$TOTAL ($PERCENT%)"
    echo "   Resets at: $RESET_TIME"
    return 1
  elif [ "$PERCENT" -lt 30 ]; then
    echo "⚠️  Rate limit low: $REMAINING/$TOTAL ($PERCENT%)"
  else
    echo "✅ Rate limit OK: $REMAINING/$TOTAL ($PERCENT%)"
  fi
  return 0
}

# Use before expensive operations
check_rate_limit || exit 1
gh api --paginate repos/{owner}/{repo}/commits
```

### Parallel Processing with Rate Limiting

```bash
#!/usr/bin/env bash
# parallel-fetch.sh - Fetch data in parallel with rate control

MAX_PARALLEL=4
PIDS=()

fetch_repo() {
  local repo=$1
  gh api "repos/$repo" > "data/${repo//\//_}.json"
}

# Read repositories from file
while read repo; do
  # Check if we've hit max parallel
  while [ ${#PIDS[@]} -ge $MAX_PARALLEL ]; do
    # Wait for any job to finish
    wait -n
    # Remove finished PIDs
    PIDS=()
    for pid in ${PIDS[@]}; do
      if kill -0 $pid 2>/dev/null; then
        PIDS+=($pid)
      fi
    done
  done

  # Start new job
  fetch_repo "$repo" &
  PIDS+=($!)
done < repos.txt

# Wait for all remaining jobs
wait
```

### Retry Logic

```bash
#!/usr/bin/env bash
# retry-command.sh - Retry gh commands with exponential backoff

retry() {
  local max_attempts=3
  local timeout=1
  local attempt=1
  local exitCode=0

  while [ $attempt -le $max_attempts ]; do
    if "$@"; then
      return 0
    else
      exitCode=$?
    fi

    echo "Attempt $attempt failed. Retrying in ${timeout}s..." >&2
    sleep "$timeout"
    attempt=$((attempt + 1))
    timeout=$((timeout * 2))
  done

  echo "Command failed after $max_attempts attempts" >&2
  return $exitCode
}

# Usage
retry gh api repos/{owner}/{repo}
retry gh pr merge 123
```

### Caching Responses

```bash
#!/usr/bin/env bash
# cached-fetch.sh - Cache gh api responses to filesystem

CACHE_DIR="${HOME}/.cache/gh-api"
mkdir -p "$CACHE_DIR"

cached_api() {
  local endpoint=$1
  local cache_key=$(echo "$endpoint" | md5sum | cut -d' ' -f1)
  local cache_file="$CACHE_DIR/$cache_key"
  local max_age=3600  # 1 hour

  # Check cache
  if [ -f "$cache_file" ]; then
    local age=$(($(date +%s) - $(stat -f %m "$cache_file")))
    if [ $age -lt $max_age ]; then
      cat "$cache_file"
      return 0
    fi
  fi

  # Fetch and cache
  gh api "$endpoint" | tee "$cache_file"
}

# Usage
cached_api "repos/{owner}/{repo}"
```

### Multi-Repository Operations

```bash
#!/usr/bin/env bash
# multi-repo-sync.sh - Sync operation across multiple repos

REPOS=(
  "org/repo1"
  "org/repo2"
  "org/repo3"
)

for repo in "${REPOS[@]}"; do
  echo "=== Processing $repo ==="
  export GH_REPO="$repo"

  # Create issue in each repo
  gh issue create \
    --title "Security update required" \
    --body "Please update dependencies" \
    --label "security"

  # Or update settings
  gh api -X PATCH "repos/$repo" \
    -f has_issues=true \
    -f has_wiki=false
done
```

## Error Handling

### Graceful Failure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Function with error handling
safe_pr_view() {
  local pr=$1
  if ! gh pr view "$pr" 2>/dev/null; then
    echo "Warning: PR #$pr not found" >&2
    return 1
  fi
}

# Continue on error
for pr in 123 456 789; do
  safe_pr_view "$pr" || continue
done
```

### Error Messages

```bash
#!/usr/bin/env bash

# Capture stderr
ERROR=$(gh pr view 999 2>&1 >/dev/null)
if [ $? -ne 0 ]; then
  echo "Error occurred: $ERROR" >&2
  exit 1
fi

# Parse API errors
if ! RESPONSE=$(gh api repos/{owner}/{repo} 2>&1); then
  MESSAGE=$(echo "$RESPONSE" | jq -r '.message' 2>/dev/null || echo "$RESPONSE")
  echo "API Error: $MESSAGE" >&2
  exit 1
fi
```

### Validation

```bash
#!/usr/bin/env bash

# Check if PR exists before operations
validate_pr() {
  local pr=$1
  if ! gh pr view "$pr" &>/dev/null; then
    echo "Error: PR #$pr does not exist" >&2
    return 1
  fi
}

# Check authentication
if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated. Run 'gh auth login'" >&2
  exit 1
fi

# Validate repository
if ! gh repo view &>/dev/null; then
  echo "Error: Not in a GitHub repository" >&2
  exit 1
fi
```

## Best Practices

### 1. Disable Pager for Scripts

```bash
export GH_PAGER=""
# or
gh config set pager ""
```

### 2. Use JSON Output for Parsing

```bash
# ❌ Fragile - depends on output format
gh pr list | cut -f1

# ✅ Robust - JSON parsing
gh pr list --json number --jq '.[].number'
```

### 3. Explicit Field Selection

```bash
# ❌ Fetches all fields (slow, large response)
gh pr list --json number

# ✅ Only needed fields
gh pr list --json number,title,state
```

### 4. Use Repository Context

```bash
# ❌ Hardcoded
gh api repos/octocat/hello-world

# ✅ Use placeholders
gh api repos/{owner}/{repo}

# ✅ Set context
export GH_REPO="octocat/hello-world"
gh api repos/{owner}/{repo}
```

### 5. Handle Rate Limits

```bash
# Check before expensive operations
if [ $(gh api rate_limit --jq '.rate.remaining') -lt 100 ]; then
  echo "Rate limit low, aborting"
  exit 1
fi

# Use caching
gh api --cache 1h repos/{owner}/{repo}
```

### 6. Idempotent Operations

```bash
# ❌ Fails if label already exists
gh label create bug --color ff0000

# ✅ Idempotent
gh label list --json name --jq '.[].name' | grep -q "^bug$" || \
  gh label create bug --color ff0000
```

### 7. Logging & Debugging

```bash
# Enable debug mode
export GH_DEBUG=api

# Log operations
exec 1> >(tee -a script.log)
exec 2> >(tee -a script.log >&2)

# Timestamp logs
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}
```

### 8. Security Considerations

```bash
# ❌ Token in script
GITHUB_TOKEN="ghp_xxxx"

# ✅ From environment or gh config
GITHUB_TOKEN=$(gh config get -h github.com oauth_token)

# ❌ Sensitive data in logs
echo "Token: $GITHUB_TOKEN"

# ✅ Redact sensitive data
echo "Token: ${GITHUB_TOKEN:0:7}..."
```

### 9. Cross-Platform Compatibility

```bash
# ❌ GNU date specific
date -d "7 days ago"

# ✅ Cross-platform (requires dateutils)
if command -v gdate >/dev/null; then
  date_cmd=gdate
else
  date_cmd=date
fi
$date_cmd -d "7 days ago"
```

### 10. Progress Indicators

```bash
# For long-running operations
total=$(gh pr list --json number --jq 'length')
current=0

gh pr list --json number --jq '.[].number' | while read pr; do
  current=$((current + 1))
  echo -ne "Processing PR $pr ($current/$total)\\r"
  gh pr view "$pr" > /dev/null
done
echo ""
```

## Template Scripts

### Minimal Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check prerequisites
if ! command -v gh &>/dev/null; then
  echo "Error: gh not installed" >&2
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated" >&2
  exit 1
fi

# Your code here
gh pr list
```

### Full-Featured Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/script.log"
CACHE_DIR="${HOME}/.cache/gh-script"

# Functions
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" >&2
}

error() {
  log "ERROR: $*"
  exit 1
}

check_rate_limit() {
  local remaining=$(gh api rate_limit --jq '.rate.remaining')
  if [ "$remaining" -lt 100 ]; then
    error "Rate limit too low: $remaining"
  fi
}

cleanup() {
  log "Cleaning up..."
  # Cleanup code here
}

# Setup
trap cleanup EXIT
mkdir -p "$CACHE_DIR"
export GH_PAGER=""

# Validation
command -v gh &>/dev/null || error "gh not installed"
gh auth status &>/dev/null || error "Not authenticated"

# Main logic
log "Starting script"
check_rate_limit

# Your code here

log "Script complete"
```

## Additional Resources

- gh Manual: https://cli.github.com/manual/
- Scripting Guide: https://github.blog/engineering/engineering-principles/scripting-with-github-cli/
- Shell Style Guide: https://google.github.io/styleguide/shellguide.html
- jq Manual: https://stedolan.github.io/jq/manual/
