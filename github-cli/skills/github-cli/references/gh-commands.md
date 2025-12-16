# GitHub CLI Complete Command Reference

This reference provides a comprehensive catalog of all `gh` commands organized by category. Use this for detailed
command exploration and discovering available functionality.

## Authentication & Configuration

### gh auth - Manage authentication

```bash
gh auth login                    # Interactive login
gh auth logout [--hostname]      # Logout from GitHub
gh auth refresh                  # Refresh authentication token
gh auth status                   # View authentication status
gh auth switch                   # Switch between authenticated accounts
gh auth token                    # Print authentication token
gh auth setup-git                # Configure git to use gh for auth
```

**Common flags:**

- `--hostname` - GitHub instance (default: github.com)
- `--web` - Open browser for authentication

### gh config - Manage configuration

```bash
gh config get <key>              # Get configuration value
gh config set <key> <value>      # Set configuration value
gh config list                   # List all configuration
gh config clear-cache            # Clear CLI cache
```

**Common keys:**

- `editor` - Default text editor
- `pager` - Output pager program
- `git_protocol` - Git protocol (https/ssh)
- `prompt` - Enable/disable prompts

### gh alias - Create command shortcuts

```bash
gh alias set <name> <expansion>  # Create alias
gh alias list                    # List all aliases
gh alias delete <name>           # Delete alias
gh alias import <file>           # Import aliases from file
```

**Examples:**

```bash
gh alias set prd "pr create --draft"
gh alias set bugs "issue list --label bug"
gh alias set co "pr checkout"
```

## Repository Management

### gh repo - Work with repositories

```bash
# View
gh repo view [<repo>]            # View repository details
gh repo view --web               # Open in browser
gh repo list [<owner>]           # List repositories
gh repo list --limit 100         # List with pagination

# Create & Fork
gh repo create [<name>]          # Create new repository (⚠️ Write)
gh repo fork [<repo>]            # Fork repository (⚠️ Write)

# Modify
gh repo edit                     # Edit repository settings (⚠️ Write)
gh repo rename <name>            # Rename repository (⚠️ Write)
gh repo archive                  # Archive repository (⚠️ Write)
gh repo unarchive                # Unarchive repository (⚠️ Write)
gh repo delete [<repo>]          # Delete repository (⚠️ Write)

# Clone & Sync
gh repo clone <repo> [<dir>]     # Clone repository
gh repo sync                     # Sync forked repository (⚠️ Write)
gh repo set-default [<repo>]     # Set default repository
```

**Subcommands:**

```bash
gh repo autolink list            # List autolink references
gh repo autolink delete <id>     # Delete autolink (⚠️ Write)
gh repo deploy-key list          # List deploy keys
gh repo deploy-key add <key>     # Add deploy key (⚠️ Write)
gh repo deploy-key delete <id>   # Delete deploy key (⚠️ Write)
gh repo gitignore list           # List gitignore templates
gh repo gitignore get <name>     # Get gitignore template
gh repo license list             # List license templates
gh repo license view <name>      # View license template
```

## Pull Requests

### gh pr - Work with pull requests

```bash
# List & View
gh pr list                       # List PRs
gh pr list --author "@me"        # Filter by author
gh pr list --assignee "@me"      # Filter by assignee
gh pr list --label <label>       # Filter by label
gh pr list --state {open|closed|merged|all}
gh pr view [<number>]            # View PR details
gh pr view --web                 # Open PR in browser
gh pr diff [<number>]            # View PR diff

# Create
gh pr create                     # Create PR (⚠️ Write)
gh pr create --draft             # Create draft PR (⚠️ Write)
gh pr create --title "..." --body "..."
gh pr create --base <branch> --head <branch>
gh pr create --assignee @me --reviewer @user
gh pr create --label bug,feature --milestone v1.0

# Checkout
gh pr checkout <number>          # Checkout PR branch locally

# Status & Checks
gh pr status                     # Show status of PRs
gh pr checks [<number>]          # View status checks
gh pr checks --watch             # Watch checks in real-time

# Modify (⚠️ All write operations)
gh pr edit [<number>]            # Edit PR
gh pr close [<number>]           # Close PR
gh pr reopen [<number>]          # Reopen PR
gh pr ready [<number>]           # Mark draft as ready
gh pr merge [<number>]           # Merge PR
gh pr merge --squash             # Squash merge
gh pr merge --rebase             # Rebase merge
gh pr merge --merge              # Regular merge
gh pr merge --auto               # Enable auto-merge

# Review
gh pr review [<number>]          # Review PR (⚠️ Write)
gh pr review --approve           # Approve PR
gh pr review --request-changes   # Request changes
gh pr review --comment           # Comment review
gh pr review --body "..."        # Add review comment

# Comment
gh pr comment [<number>]         # Add comment (⚠️ Write)
gh pr comment --body "..."

# Advanced
gh pr lock [<number>]            # Lock conversation (⚠️ Write)
gh pr unlock [<number>]          # Unlock conversation (⚠️ Write)
gh pr revert [<number>]          # Revert PR (⚠️ Write)
gh pr update-branch [<number>]   # Update PR branch (⚠️ Write)
```

**Common flags:**

- `--json <fields>` - Output as JSON
- `--jq <expression>` - Filter JSON output
- `--template <string>` - Format with Go template
- `--limit <number>` - Pagination limit
- `--web` - Open in browser

## Issues

### gh issue - Manage issues

```bash
# List & View
gh issue list                    # List issues
gh issue list --author "@me"     # Filter by author
gh issue list --assignee "@me"   # Filter by assignee
gh issue list --label <label>    # Filter by label
gh issue list --mention "@me"    # Filter by mention
gh issue list --state {open|closed|all}
gh issue view [<number>]         # View issue details
gh issue view --web              # Open issue in browser

# Create
gh issue create                  # Create issue (⚠️ Write)
gh issue create --title "..." --body "..."
gh issue create --assignee @me --label bug --milestone v1.0

# Modify (⚠️ All write operations)
gh issue edit [<number>]         # Edit issue
gh issue close [<number>]        # Close issue
gh issue reopen [<number>]       # Reopen issue
gh issue pin [<number>]          # Pin issue
gh issue unpin [<number>]        # Unpin issue
gh issue lock [<number>]         # Lock conversation
gh issue unlock [<number>]       # Unlock conversation
gh issue delete [<number>]       # Delete issue
gh issue transfer <repo>         # Transfer issue to another repo

# Comment
gh issue comment [<number>]      # Add comment (⚠️ Write)
gh issue comment --body "..."

# Status
gh issue status                  # Show status of issues
gh issue develop [<number>]      # Start developing an issue
```

## GitHub Actions

### gh workflow - Manage workflows

```bash
gh workflow list                 # List workflows
gh workflow view <workflow>      # View workflow details
gh workflow view --yaml          # Show workflow YAML
gh workflow view --web           # Open in browser

gh workflow run <workflow>       # Run workflow (⚠️ Write)
gh workflow run --ref <branch>   # Run on specific ref
gh workflow run -f key=value     # Pass workflow inputs

gh workflow enable <workflow>    # Enable workflow (⚠️ Write)
gh workflow disable <workflow>   # Disable workflow (⚠️ Write)
```

### gh run - Manage workflow runs

```bash
# List & View
gh run list                      # List workflow runs
gh run list --workflow <name>    # Filter by workflow
gh run list --branch <branch>    # Filter by branch
gh run list --user <user>        # Filter by user
gh run view [<run-id>]           # View run details
gh run view --log                # View logs
gh run view --log-failed         # View failed logs only
gh run watch [<run-id>]          # Watch run in real-time

# Download
gh run download [<run-id>]       # Download artifacts
gh run download --name <name>    # Download specific artifact

# Modify (⚠️ All write operations)
gh run cancel [<run-id>]         # Cancel run
gh run delete [<run-id>]         # Delete run
gh run rerun [<run-id>]          # Rerun workflow
gh run rerun --failed            # Rerun failed jobs only
```

### gh cache - Manage Actions cache

```bash
gh cache list                    # List cache entries
gh cache list --key <pattern>    # Filter by key pattern
gh cache delete <cache-id>       # Delete cache entry (⚠️ Write)
gh cache delete --all            # Delete all cache (⚠️ Write)
```

## Releases

### gh release - Manage releases

```bash
# List & View
gh release list                  # List releases
gh release list --limit 50       # Paginate results
gh release view [<tag>]          # View release details
gh release view --web            # Open in browser

# Download
gh release download [<tag>]      # Download release assets
gh release download --pattern "*.tar.gz"
gh release download --archive tar.gz

# Create (⚠️ Write)
gh release create <tag>          # Create release
gh release create <tag> <files>  # Create with assets
gh release create --title "..." --notes "..."
gh release create --draft        # Create as draft
gh release create --prerelease   # Mark as prerelease
gh release create --generate-notes  # Auto-generate notes
gh release create --discussion-category "Announcements"

# Modify (⚠️ All write operations)
gh release edit <tag>            # Edit release
gh release delete <tag>          # Delete release
gh release delete-asset <tag> <asset>  # Delete asset
gh release upload <tag> <files>  # Upload assets

# Verify
gh release verify <tag> <file>   # Verify artifact attestation
gh release verify-asset <tag> <asset>
```

## Gists

### gh gist - Manage gists

```bash
# List & View
gh gist list                     # List gists
gh gist list --public            # List public gists only
gh gist list --secret            # List secret gists only
gh gist view <gist-id>           # View gist content
gh gist view --web               # Open in browser

# Create (⚠️ Write)
gh gist create [<files>]         # Create gist
gh gist create --public          # Create public gist
gh gist create --desc "..."      # Add description

# Clone & Edit
gh gist clone <gist-id>          # Clone gist repository
gh gist edit <gist-id>           # Edit gist (⚠️ Write)
gh gist rename <gist-id> <filename>  # Rename gist file (⚠️ Write)

# Delete
gh gist delete <gist-id>         # Delete gist (⚠️ Write)
```

## Projects

### gh project - Manage GitHub Projects

```bash
# List & View
gh project list                  # List projects
gh project list --owner <owner>  # Filter by owner
gh project view <number>         # View project details
gh project view --web            # Open in browser

# Create & Modify (⚠️ All write operations)
gh project create               # Create project
gh project create --title "..." --owner <owner>
gh project edit <number>        # Edit project
gh project close <number>       # Close project
gh project delete <number>      # Delete project
gh project copy <number>        # Copy project

# Items
gh project item-add <number> --url <issue-or-pr-url>
gh project item-edit --id <item-id> --field-id <field-id> --value <value>
gh project item-delete --id <item-id>
gh project item-list <number>
gh project item-create <number>
gh project item-archive --id <item-id>

# Fields
gh project field-list <number>
gh project field-create <number> --name <name> --data-type <type>
gh project field-delete --id <field-id>

# Link/Unlink
gh project link <number> [--owner <owner>]
gh project unlink <number> [--owner <owner>]
```

## Search

### gh search - Search GitHub

```bash
# Search PRs
gh search prs <query>
gh search prs "is:open is:pr author:@me"
gh search prs --review-requested=@me --state=open
gh search prs --assignee=@me --label=bug

# Search Issues
gh search issues <query>
gh search issues "is:issue is:open label:bug"
gh search issues --assignee=@me --label=priority

# Search Code
gh search code <query>
gh search code "function calculateTotal"
gh search code --extension js --filename routes

# Search Commits
gh search commits <query>
gh search commits "fix typo" --author=@me

# Search Repos
gh search repos <query>
gh search repos "topic:machine-learning language:python"
gh search repos --stars ">1000" --language go
```

**Common search qualifiers:**

- `is:{issue|pr|open|closed|merged}`
- `author:<username>`, `@me`
- `assignee:<username>`
- `label:<label>`
- `state:{open|closed}`
- `language:<language>`
- `stars:>N`, `forks:>N`
- `created:>YYYY-MM-DD`, `updated:<YYYY-MM-DD`

## Codespaces

### gh codespace - Manage codespaces

```bash
# List & View
gh codespace list               # List codespaces
gh codespace view              # View details
gh cs list                     # Shorthand alias

# Create & Delete (⚠️ Write operations)
gh codespace create            # Create codespace
gh codespace create --repo <owner/repo>
gh codespace delete            # Delete codespace
gh codespace stop              # Stop codespace
gh codespace rebuild           # Rebuild codespace

# Connect
gh codespace code             # Open in VS Code
gh codespace code -w          # Open in VS Code web
gh codespace ssh              # Connect via SSH
gh codespace cp <src> <dest>  # Copy files
gh codespace jupyter          # Open Jupyter notebook

# Manage
gh codespace edit             # Edit codespace settings (⚠️ Write)
gh codespace logs             # View logs
gh codespace ports            # Manage port forwarding
```

## API Access

### gh api - Make API requests

```bash
# REST API (v3)
gh api <endpoint>               # GET request (default)
gh api /repos/{owner}/{repo}
gh api repos/{owner}/{repo}/releases
gh api -X GET <endpoint>        # Explicit GET

# HTTP Methods
gh api -X POST <endpoint>       # POST (⚠️ Write)
gh api -X PUT <endpoint>        # PUT (⚠️ Write)
gh api -X PATCH <endpoint>      # PATCH (⚠️ Write)
gh api -X DELETE <endpoint>     # DELETE (⚠️ Write)
gh api --method POST <endpoint> # Alternative syntax

# Parameters
gh api <endpoint> -f key=value  # Raw field
gh api <endpoint> -F key=value  # Typed field
gh api <endpoint> --input file  # Read from file/stdin

# GraphQL (v4)
gh api graphql -f query='...'
gh api graphql -F var=value -f query='...'

# Advanced
gh api --paginate <endpoint>    # Auto-paginate results
gh api --cache 1h <endpoint>    # Cache response
gh api -q '.field' <endpoint>   # Filter with jq
gh api -t '{{.field}}' <endpoint>  # Format with template
gh api --include <endpoint>     # Include HTTP headers
gh api --verbose <endpoint>     # Verbose output
```

## Secrets & Variables

### gh secret - Manage secrets

```bash
gh secret list                  # List secrets
gh secret set <name>            # Set secret (⚠️ Write)
gh secret set <name> --body "value"
gh secret set <name> < file
gh secret delete <name>         # Delete secret (⚠️ Write)
```

**Scopes:**

- `-o`, `--org` - Organization secrets
- `-e`, `--env` - Environment secrets
- `-u`, `--user` - User secrets (codespaces)

### gh variable - Manage variables

```bash
gh variable list                # List variables
gh variable get <name>          # Get variable value
gh variable set <name>          # Set variable (⚠️ Write)
gh variable set <name> --body "value"
gh variable delete <name>       # Delete variable (⚠️ Write)
```

## SSH & GPG Keys

### gh ssh-key - Manage SSH keys

```bash
gh ssh-key list                 # List SSH keys
gh ssh-key add <file>           # Add SSH key (⚠️ Write)
gh ssh-key add --title "Work laptop" ~/.ssh/id_rsa.pub
gh ssh-key delete <id>          # Delete SSH key (⚠️ Write)
```

### gh gpg-key - Manage GPG keys

```bash
gh gpg-key list                 # List GPG keys
gh gpg-key add <file>           # Add GPG key (⚠️ Write)
gh gpg-key delete <id>          # Delete GPG key (⚠️ Write)
```

## Labels & Milestones

### gh label - Manage labels

```bash
gh label list                   # List labels
gh label create <name>          # Create label (⚠️ Write)
gh label create <name> --description "..." --color "ff0000"
gh label edit <name>            # Edit label (⚠️ Write)
gh label delete <name>          # Delete label (⚠️ Write)
gh label clone <source-repo>   # Clone labels from repo (⚠️ Write)
```

## Attestation

### gh attestation - Verify artifacts

```bash
gh attestation verify <file>    # Verify artifact attestation
gh attestation download <file>  # Download attestation
gh attestation trusted-root     # Get trusted root
```

## Extensions

### gh extension - Manage extensions

```bash
gh extension list               # List installed extensions
gh extension search <query>     # Search extensions
gh extension browse             # Browse extensions
gh extension install <repo>     # Install extension (⚠️ Write)
gh extension upgrade [<ext>]    # Upgrade extension (⚠️ Write)
gh extension upgrade --all      # Upgrade all extensions (⚠️ Write)
gh extension remove <ext>       # Remove extension (⚠️ Write)
gh extension create <name>      # Create extension (⚠️ Write)
gh extension exec <ext> <args>  # Execute extension command
```

## Organization

### gh org - Organization operations

```bash
gh org list                     # List organizations
```

## Rulesets

### gh ruleset - Repository rulesets

```bash
gh ruleset list                 # List rulesets
gh ruleset view <id>            # View ruleset details
gh ruleset check <branch>       # Check rules for branch
```

## Utilities

### gh browse - Open in browser

```bash
gh browse                       # Open repository in browser
gh browse <number>              # Open PR/issue in browser
gh browse --branch <branch>     # Open specific branch
gh browse --commit <sha>        # Open specific commit
gh browse --settings            # Open repository settings
```

### gh status - View status

```bash
gh status                       # View GitHub status dashboard
```

### gh agent-task - Manage agent tasks

```bash
gh agent-task list              # List agent tasks
gh agent-task view <id>         # View task details
gh agent-task create            # Create agent task (⚠️ Write)
```

### gh completion - Shell completion

```bash
gh completion --shell bash      # Generate bash completion
gh completion --shell zsh       # Generate zsh completion
gh completion --shell fish      # Generate fish completion
gh completion --shell powershell  # Generate PowerShell completion
```

### gh help - Documentation

```bash
gh help                         # Show help
gh help <command>               # Show command help
gh help environment             # Environment variables
gh help exit-codes              # Exit codes reference
gh help formatting              # Output formatting
gh help mintty                  # MinTTY compatibility
gh help reference               # Complete command reference
```

## Legend

- ⚠️ **Write operation** - Blocked by default, requires user permission
- No marker - Read-only operation, always allowed

## Common Flags (Most Commands)

- `--help` - Show help for command
- `--repo <owner/repo>` - Specify repository
- `--hostname <host>` - GitHub hostname
- `--json <fields>` - Output as JSON
- `--jq <expression>` - Filter JSON with jq
- `--template <string>` - Format with Go template
- `--web` - Open in web browser
