# GitHub CLI API Patterns Reference

Comprehensive guide to using `gh api` for REST and GraphQL API access, including authentication, pagination, caching, and advanced patterns.

## Table of Contents

1. [REST API (v3)](#rest-api-v3)
2. [GraphQL API (v4)](#graphql-api-v4)
3. [Authentication](#authentication)
4. [HTTP Methods & Security](#http-methods--security)
5. [Parameters & Data](#parameters--data)
6. [Pagination](#pagination)
7. [Caching](#caching)
8. [Output Formatting](#output-formatting)
9. [Advanced Patterns](#advanced-patterns)
10. [Common Use Cases](#common-use-cases)

## REST API (v3)

### Basic Requests

```bash
# Default GET request
gh api repos/{owner}/{repo}

# Explicit GET
gh api -X GET repos/{owner}/{repo}

# Full path
gh api /repos/owner/repo

# Relative to repository context
gh api repos/{owner}/{repo}/releases
```

### Placeholder Substitution

gh automatically replaces placeholders from current repository context or `GH_REPO` environment variable:

```bash
# In a repository directory
gh api repos/{owner}/{repo}/issues     # Auto-fills owner and repo

# Override with environment variable
export GH_REPO="octocat/hello-world"
gh api repos/{owner}/{repo}

# Placeholders: {owner}, {repo}, {branch}
gh api repos/{owner}/{repo}/branches/{branch}
```

### Endpoint Examples

```bash
# Repositories
gh api repos/{owner}/{repo}
gh api repos/{owner}/{repo}/contributors
gh api repos/{owner}/{repo}/languages
gh api repos/{owner}/{repo}/topics
gh api repos/{owner}/{repo}/tags

# Issues
gh api repos/{owner}/{repo}/issues
gh api repos/{owner}/{repo}/issues/{issue_number}
gh api repos/{owner}/{repo}/issues/{issue_number}/comments
gh api repos/{owner}/{repo}/issues/{issue_number}/events

# Pull Requests
gh api repos/{owner}/{repo}/pulls
gh api repos/{owner}/{repo}/pulls/{pull_number}
gh api repos/{owner}/{repo}/pulls/{pull_number}/commits
gh api repos/{owner}/{repo}/pulls/{pull_number}/files
gh api repos/{owner}/{repo}/pulls/{pull_number}/reviews

# Branches & Commits
gh api repos/{owner}/{repo}/branches
gh api repos/{owner}/{repo}/branches/{branch}
gh api repos/{owner}/{repo}/commits
gh api repos/{owner}/{repo}/commits/{sha}
gh api repos/{owner}/{repo}/commits/{sha}/status

# Releases
gh api repos/{owner}/{repo}/releases
gh api repos/{owner}/{repo}/releases/latest
gh api repos/{owner}/{repo}/releases/tags/{tag}

# Workflows & Runs
gh api repos/{owner}/{repo}/actions/workflows
gh api repos/{owner}/{repo}/actions/runs
gh api repos/{owner}/{repo}/actions/runs/{run_id}
gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs

# Users & Organizations
gh api user
gh api users/{username}
gh api orgs/{org}
gh api orgs/{org}/repos
gh api orgs/{org}/members
```

## GraphQL API (v4)

### Basic Query

```bash
gh api graphql -f query='
  query {
    viewer {
      login
      name
      email
    }
  }
'
```

### Query with Variables

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      name
      description
      stargazerCount
      forkCount
    }
  }
' -f owner=octocat -f repo=hello-world
```

### Pagination in GraphQL

```bash
gh api graphql --paginate -f query='
  query($endCursor: String) {
    repository(owner: "owner", name: "repo") {
      issues(first: 100, after: $endCursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          number
          title
          state
        }
      }
    }
  }
'
```

**Requirements for pagination:**
- Query must accept `$endCursor` variable
- Query must fetch `pageInfo { hasNextPage, endCursor }` fields

### Complex GraphQL Examples

#### Repository Stats

```bash
gh api graphql -f query='
  query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      name
      stargazerCount
      forkCount
      watchers {
        totalCount
      }
      issues(states: OPEN) {
        totalCount
      }
      pullRequests(states: OPEN) {
        totalCount
      }
    }
  }
' -f owner=owner -f name=repo
```

#### Recent Pull Requests with Reviews

```bash
gh api graphql -f query='
  query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      pullRequests(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {
        nodes {
          number
          title
          author {
            login
          }
          reviews(first: 10) {
            nodes {
              author {
                login
              }
              state
            }
          }
        }
      }
    }
  }
' -f owner=owner -f name=repo
```

#### User Contribution Stats

```bash
gh api graphql -f query='
  query($username: String!) {
    user(login: $username) {
      contributionsCollection {
        totalCommitContributions
        totalIssueContributions
        totalPullRequestContributions
        totalPullRequestReviewContributions
      }
    }
  }
' -f username=octocat
```

## Authentication

### Automatic Authentication

`gh api` automatically uses authentication from `gh auth login`:

```bash
# Check authentication status
gh auth status

# The token is used automatically
gh api user                     # Authenticated request
```

### Manual Token

```bash
# Set token via environment variable
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
gh api user

# Token from gh config
export GITHUB_TOKEN=$(gh config get -h github.com oauth_token)
```

### Multiple GitHub Instances

```bash
# GitHub Enterprise
gh api --hostname github.example.com repos/{owner}/{repo}

# Switch between accounts
gh auth switch
gh api user
```

## HTTP Methods & Security

### Read Operations (Allowed)

```bash
# GET (default method)
gh api repos/{owner}/{repo}
gh api -X GET repos/{owner}/{repo}
gh api --method GET repos/{owner}/{repo}

# HEAD (check resource existence)
gh api -X HEAD repos/{owner}/{repo}

# OPTIONS (check available methods)
gh api -X OPTIONS repos/{owner}/{repo}
```

### Write Operations (⚠️ Blocked by Default)

All write methods require explicit user permission:

```bash
# POST - Create resource
gh api -X POST repos/{owner}/{repo}/issues \
  -f title="Bug report" \
  -f body="Description"

# PUT - Replace resource
gh api -X PUT repos/{owner}/{repo}/topics \
  -f names[]="javascript" \
  -f names[]="react"

# PATCH - Update resource
gh api -X PATCH repos/{owner}/{repo}/issues/{issue_number} \
  -f state="closed"

# DELETE - Remove resource
gh api -X DELETE repos/{owner}/{repo}/issues/{issue_number}/lock
```

### Implicit POST via Field Parameters

Field parameters (`-f`, `-F`) trigger POST unless `-X GET` is specified:

```bash
# ❌ Blocked - Implicit POST
gh api repos/{owner}/{repo}/issues -f state=open

# ✅ Allowed - Explicit GET
gh api -X GET repos/{owner}/{repo}/issues -f state=open
```

## Parameters & Data

### Raw Field Parameters (-f)

Static string values:

```bash
# Single parameter
gh api -X POST repos/{owner}/{repo}/issues \
  -f title="Bug: Login fails"

# Multiple parameters
gh api -X POST repos/{owner}/{repo}/issues \
  -f title="Feature request" \
  -f body="Add dark mode" \
  -f assignee="octocat"
```

### Typed Field Parameters (-F)

Automatic type conversion:

```bash
# Boolean
gh api -X PATCH repos/{owner}/{repo} -F has_issues=true

# Integer
gh api -X PATCH repos/{owner}/{repo} -F allow_squash_merge=1

# Null
gh api -X PATCH repos/{owner}/{repo}/issues/1 -F milestone=null

# File content (prefix with @)
gh api -X POST gists -F 'files[hello.txt][content]=@hello.txt'

# Placeholder substitution (prefix with :)
gh api -X POST repos/{owner}/{repo}/issues \
  -F 'assignees[]=:username'
```

### Nested Parameters

Use bracket notation for nested objects and arrays:

```bash
# Nested object
gh api -X POST gists \
  -f 'files[hello.txt][content]=Hello World'

# Array
gh api -X PUT repos/{owner}/{repo}/topics \
  -f 'names[]=javascript' \
  -f 'names[]=typescript' \
  -f 'names[]=react'

# Complex nested structure
gh api -X POST repos/{owner}/{repo}/issues \
  -f title="Bug" \
  -f 'labels[]=bug' \
  -f 'labels[]=priority-high'
```

### Input from File/Stdin

```bash
# From file
gh api -X POST repos/{owner}/{repo}/issues --input issue.json

# From stdin
echo '{"title":"Bug","body":"Description"}' | \
  gh api -X POST repos/{owner}/{repo}/issues --input -

# From heredoc
gh api -X POST repos/{owner}/{repo}/issues --input - <<EOF
{
  "title": "Bug report",
  "body": "Detailed description",
  "labels": ["bug", "priority-high"]
}
EOF
```

## Pagination

### Automatic REST Pagination

```bash
# Fetch all pages
gh api --paginate repos/{owner}/{repo}/issues

# Pagination happens automatically for endpoints with Link header
gh api --paginate repos/{owner}/{repo}/commits

# Combine pages into single array with --slurp
gh api --paginate --slurp repos/{owner}/{repo}/issues
```

### Manual REST Pagination

```bash
# First page (default)
gh api repos/{owner}/{repo}/issues

# Specific page
gh api repos/{owner}/{repo}/issues?page=2&per_page=100

# Pagination with parameters
gh api -X GET repos/{owner}/{repo}/issues \
  -f page=2 \
  -f per_page=100 \
  -f state=closed
```

### GraphQL Pagination

```bash
gh api graphql --paginate -f query='
  query($endCursor: String) {
    repository(owner: "owner", name: "repo") {
      issues(first: 100, after: $endCursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          number
          title
        }
      }
    }
  }
'
```

## Caching

### Cache Duration

```bash
# Cache for 1 hour
gh api --cache 1h repos/{owner}/{repo}

# Cache for 30 minutes
gh api --cache 30m repos/{owner}/{repo}/releases

# Cache for 3600 seconds
gh api --cache 3600s repos/{owner}/{repo}
```

### Cache Use Cases

```bash
# Frequently accessed static data
gh api --cache 24h repos/{owner}/{repo}/license

# Repository metadata
gh api --cache 1h repos/{owner}/{repo}

# Rate limit check
gh api --cache 5m rate_limit
```

## Output Formatting

### JSON Output

```bash
# Default JSON output
gh api repos/{owner}/{repo}

# Specific fields as JSON
gh api repos/{owner}/{repo} --json name,description,stargazers_count
```

### jq Filtering

```bash
# Extract single field
gh api repos/{owner}/{repo} --jq '.name'

# Extract multiple fields
gh api repos/{owner}/{repo} --jq '{name, stars: .stargazers_count}'

# Array transformation
gh api repos/{owner}/{repo}/issues --jq '.[].title'

# Conditional filtering
gh api repos/{owner}/{repo}/issues --jq '.[] | select(.state == "open")'

# Complex transformation
gh api repos/{owner}/{repo}/contributors --jq '
  [.[] | {
    username: .login,
    contributions: .contributions
  }] | sort_by(.contributions) | reverse | .[0:10]
'
```

### Go Template Formatting

```bash
# Simple template
gh api repos/{owner}/{repo} --template '{{.name}}: {{.stargazers_count}} stars'

# Iterate array
gh api repos/{owner}/{repo}/issues --template '
  {{range .}}
  #{{.number}}: {{.title}}
  {{end}}
'

# Conditional logic
gh api repos/{owner}/{repo} --template '
  {{if .private}}Private{{else}}Public{{end}} repository
'
```

### Include HTTP Headers

```bash
# Show response headers and status
gh api --include repos/{owner}/{repo}

# Useful for debugging rate limits
gh api --include rate_limit
```

### Verbose Output

```bash
# Show full request/response
gh api --verbose repos/{owner}/{repo}

# Debug API calls
gh api --verbose -X POST repos/{owner}/{repo}/issues -f title="Test"
```

## Advanced Patterns

### Preview Features

Enable experimental API features:

```bash
# Single preview
gh api -p reactions repos/{owner}/{repo}/issues/{issue_number}/reactions

# Multiple previews
gh api -p reactions,squirrel-girl repos/{owner}/{repo}/issues

# Comma-separated or repeated flags
gh api -p reactions -p squirrel-girl repos/{owner}/{repo}/issues
```

### Rate Limit Management

```bash
# Check rate limit
gh api rate_limit --jq '.rate | {remaining, limit, reset: (.reset | todate)}'

# Check before expensive operation
REMAINING=$(gh api rate_limit --jq '.rate.remaining')
if [ "$REMAINING" -lt 100 ]; then
  echo "Rate limit low: $REMAINING requests remaining"
  exit 1
fi
```

### Conditional Requests (ETags)

```bash
# First request (save ETag)
ETAG=$(gh api --include repos/{owner}/{repo} | grep -i etag | cut -d' ' -f2)

# Subsequent request (304 if not modified)
gh api repos/{owner}/{repo} --header "If-None-Match: $ETAG"
```

### Batch Operations

```bash
# Get multiple repositories
for repo in repo1 repo2 repo3; do
  gh api repos/owner/$repo --jq '{name, stars: .stargazers_count}'
done

# Parallel requests
gh api repos/{owner}/repo1 &
gh api repos/{owner}/repo2 &
gh api repos/{owner}/repo3 &
wait
```

## Common Use Cases

### Repository Analytics

```bash
# Star history by contributor
gh api repos/{owner}/{repo}/contributors --jq '
  [.[] | {login: .login, contributions: .contributions}] |
  sort_by(.contributions) | reverse | .[0:10]
'

# Language breakdown
gh api repos/{owner}/{repo}/languages --jq '
  to_entries | map({lang: .key, bytes: .value}) | sort_by(.bytes) | reverse
'

# Recent activity
gh api repos/{owner}/{repo}/events --jq '.[0:10] | .[] | {
  type: .type,
  actor: .actor.login,
  created: .created_at
}'
```

### Issue/PR Management

```bash
# Open issues by label
gh api repos/{owner}/{repo}/issues --jq '
  [.[] | select(.state == "open" and (.labels | any(.name == "bug")))] |
  map({number, title, author: .user.login})
'

# PRs needing review
gh api repos/{owner}/{repo}/pulls --jq '
  [.[] | select(.requested_reviewers | length > 0)] |
  map({number, title, reviewers: [.requested_reviewers[].login]})
'

# Stale issues (no activity in 30 days)
gh api repos/{owner}/{repo}/issues --jq '
  [.[] | select(
    (.updated_at | fromdateiso8601) < (now - (30 * 86400))
  )] | map({number, title, updated: .updated_at})
'
```

### Team Collaboration

```bash
# Team member contributions
gh api orgs/{org}/members --jq '.[].login' | while read user; do
  echo "=== $user ==="
  gh api search/issues --jq '.total_count' \
    -f q="org:${org} author:${user} type:pr is:merged"
done

# Review workload
gh api search/issues --jq '.items | map({number, title, pr: .html_url})' \
  -f q="org:${org} is:pr is:open review-requested:@me"
```

### Release Management

```bash
# Latest release info
gh api repos/{owner}/{repo}/releases/latest --jq '{
  tag: .tag_name,
  name: .name,
  published: .published_at,
  downloads: [.assets[] | {name, count: .download_count}]
}'

# Download statistics
gh api repos/{owner}/{repo}/releases --jq '
  [.[] | {
    tag: .tag_name,
    total_downloads: ([.assets[].download_count] | add)
  }]
'
```

### Workflow Automation

```bash
# Check workflow status
gh api repos/{owner}/{repo}/actions/runs --jq '
  .workflow_runs[0] | {
    status: .status,
    conclusion: .conclusion,
    url: .html_url
  }
'

# Failed jobs in run
gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs --jq '
  [.jobs[] | select(.conclusion == "failure")] |
  map({name, conclusion, started: .started_at})
'
```

### Security & Compliance

```bash
# Check security advisories
gh api repos/{owner}/{repo}/vulnerability-alerts

# Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts

# Branch protection rules
gh api repos/{owner}/{repo}/branches/{branch}/protection --jq '{
  required_reviews: .required_pull_request_reviews.required_approving_review_count,
  dismiss_stale: .required_pull_request_reviews.dismiss_stale_reviews,
  require_code_owner: .required_pull_request_reviews.require_code_owner_reviews
}'
```

## Error Handling

```bash
# Check exit code
if gh api repos/{owner}/{repo} > /dev/null 2>&1; then
  echo "Repository exists"
else
  echo "Repository not found or access denied"
fi

# Parse error message
ERROR=$(gh api repos/{owner}/{repo}/invalid 2>&1)
echo "$ERROR" | jq -r '.message'

# Graceful degradation
gh api repos/{owner}/{repo} 2>/dev/null || echo '{"name": "unknown"}'
```

## Best Practices

1. **Use placeholders** for repository context instead of hardcoding
2. **Cache static data** to reduce API calls and rate limit usage
3. **Paginate large datasets** to avoid truncated results
4. **Filter with jq** to extract only needed data
5. **Check rate limits** before batch operations
6. **Use GraphQL** for complex queries needing multiple resources
7. **Prefer GET** with parameters over implicit POST
8. **Handle errors** gracefully with exit code checks
9. **Request minimal fields** in GraphQL to reduce response size
10. **Respect write protection** - always ask user permission first

## Security Notes

- ⚠️ All POST/PUT/PATCH/DELETE methods are blocked by default
- ⚠️ Field parameters trigger implicit POST without `-X GET`
- ⚠️ Always ask for user authorization before write operations
- ✅ GET requests are always safe and allowed
- ✅ HEAD and OPTIONS methods are safe
- ✅ Explicit `-X GET` with parameters is allowed

## Additional Resources

- REST API v3 Docs: https://docs.github.com/en/rest
- GraphQL API v4 Docs: https://docs.github.com/en/graphql
- API Rate Limits: https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
- gh api Manual: https://cli.github.com/manual/gh_api
