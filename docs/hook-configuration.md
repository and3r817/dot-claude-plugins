# Hook Configuration Format Reference

**Agent Context**: Quick reference for hooks.json structure. Consult when configuring hook events and matchers.

## When to Consult This Document

**READ when:**

- Writing hooks.json for new hook plugin
- Understanding event types (PreToolUse, PostToolUse, SessionStart)
- Configuring matchers for specific tools
- Understanding stdin JSON format for hooks

**SKIP when:**

- You already know basic hooks.json structure
- Only need to validate syntax (use `python3 -m json.tool`)

## Location

**Standard path:** `hooks/hooks.json`

**CRITICAL:** Hooks configuration is **auto-loaded** from this location. DO NOT list in plugin.json.

## Minimal Hook Configuration

**Start with this:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validator.py",
            "timeout": 1,
            "description": "What this hook does"
          }
        ]
      }
    ]
  }
}
```

**Agent Implementation:**

1. Replace `"matcher"` with target tool (Bash, Write, Edit, etc.)
2. Replace script path (MUST use `${CLAUDE_PLUGIN_ROOT}`)
3. Update description
4. Set appropriate timeout

## Event Types Reference

### PreToolUse — Validation/Enforcement

**Triggers:** Before tool execution
**Use case:** Block/validate operations before execution
**Exit codes:**

- `0` — Allow tool execution
- `2` — Block tool execution (error from stderr shown to user)

**Example:**

```json
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validator.py",
        "timeout": 1,
        "description": "Block forbidden commands"
      }
    ]
  }
]
```

**Agent Usage:** Most common event type for enforcement plugins.

### PostToolUse — Post-Processing

**Triggers:** After tool execution (only if PreToolUse allowed)
**Use case:** Logging, formatting, cleanup
**Exit codes:** Ignored (tool already executed)

**Example:**

```json
"PostToolUse": [
  {
    "matcher": "Write",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-file.py",
        "timeout": 5,
        "description": "Auto-format written files"
      }
    ]
  }
]
```

**Agent Usage:** Use when processing results AFTER tool completes.

### SessionStart — Initialization

**Triggers:** When Claude Code session starts or resumes
**Use case:** Plugin initialization, configuration loading
**Exit codes:** Ignored (informational)
**Matcher:** NOT required (session-level event)

**Example:**

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/init.sh",
        "timeout": 10,
        "description": "Load plugin configuration"
      }
    ]
  }
]
```

**Agent Usage:** Rarely needed unless plugin requires initialization.

### PermissionRequest — Permission Dialog Interception

**Triggers:** When user sees a permission dialog
**Use case:** Auto-approve/deny based on patterns, logging permission requests
**Exit codes:** 0 (proceed with dialog), 2 (deny automatically)

**Example:**

```json
"PermissionRequest": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/permission-handler.py",
        "timeout": 5,
        "description": "Auto-approve safe operations"
      }
    ]
  }
]
```

**Agent Usage:** Automate permission decisions for known-safe patterns.

### Notification — Alert Handling

**Triggers:** When Claude Code sends notifications/alerts
**Use case:** Custom notification routing, logging, external integrations
**Exit codes:** Ignored (informational)

**Example:**

```json
"Notification": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/notify-slack.sh",
        "timeout": 10,
        "description": "Send notifications to Slack"
      }
    ]
  }
]
```

**Agent Usage:** Route notifications to external systems (Slack, email, logging).

### Other Event Types

Less commonly used:

- `SessionEnd` — Session termination cleanup
- `UserPromptSubmit` — Before processing user input (stdout added as context)
- `Stop` — Main agent completion (supports `type: "prompt"` for LLM evaluation)
- `SubagentStop` — Subagent completion (supports `type: "prompt"` for LLM evaluation)
- `PreCompact` — Before context compaction

**Reference:** [Claude Code hooks documentation](https://code.claude.com/docs/en/hooks)

## Matchers Reference

### Single Tool Matcher

**Match one specific tool:**

```json
"matcher": "Bash"
"matcher": "Write"
"matcher": "Edit"
"matcher": "Read"
```

**Agent Action:** Use when hook only applies to one tool type.

### Multiple Tool Matcher (OR)

**Match any of multiple tools:**

```json
"matcher": "Write|Edit"       // Matches Write OR Edit
"matcher": "Bash|Python"       // Matches Bash OR Python
```

**Agent Action:** Use when same validation applies to multiple tools.

### Common Tool Names

**File operations:**

- `Write` — File creation
- `Edit` — File modification
- `Read` — File reading

**Search operations:**

- `Grep` — Pattern search
- `Glob` — File pattern matching

**Execution:**

- `Bash` — Shell commands
- `Python` — Python execution (if available)

### MCP Tool Matching

**Match MCP server tools with pattern:** `mcp__<server-name>__<tool-name>`

**Examples:**

```json
"matcher": "mcp__github__search_repositories"    // Specific tool
"matcher": "mcp__github__.*"                     // All github server tools
"matcher": "mcp__.*__write.*"                    // Write tools from any server
```

**Example configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__github__.*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-github.py",
            "timeout": 5,
            "description": "Validate GitHub API operations"
          }
        ]
      }
    ]
  }
}
```

**Agent Usage:** Intercept and validate MCP tool calls before execution. Useful for:

- Rate limiting API calls
- Validating parameters before sending to external services
- Logging external service interactions
- Blocking dangerous operations

### No Matcher (Session Events)

**Session-level events don't use matchers:**

```json
"SessionStart": [
  {
    "hooks": [...]  // No matcher field
  }
]
```

## Hook Fields Reference

### type

**Type:** String
**Values:** `"command"` or `"prompt"`

```json
"type": "command"   // Execute external script
"type": "prompt"    // LLM-evaluated hook (Stop/SubagentStop only)
```

**Agent Action:** Use `"command"` for validation scripts. Use `"prompt"` only for Stop/SubagentStop events requiring
context-aware decisions.

#### Prompt-Based Hooks (type: "prompt")

**Use case:** Context-aware decisions for Stop/SubagentStop events using LLM evaluation.

**Configuration:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if the task is truly complete. Check that all requirements are met and tests pass.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Return format:** LLM returns JSON with decision:

```json
{
  "decision": "approve",     // or "block"
  "reason": "All requirements met",
  "continue": false,         // Optional: continue execution
  "stopReason": "Task complete"  // Optional: reason for stopping
}
```

**Agent Usage:**

- Only for Stop/SubagentStop events (context-aware decisions)
- Uses fast LLM to evaluate conditions
- Cannot be used for PreToolUse/PostToolUse (use `"command"` instead)

### command

**Type:** String
**Value:** Path to executable script

**REQUIRED format:**

```json
"command": "${CLAUDE_PLUGIN_ROOT}/scripts/validator.py"
```

**WRONG formats:**

```json
"command": "/absolute/path/to/validator.py"  // ❌ Absolute path
"command": "./scripts/validator.py"          // ❌ Relative without variable
"command": "scripts/validator.py"            // ❌ Relative path
```

**Agent Action:** ALWAYS use `${CLAUDE_PLUGIN_ROOT}` prefix for plugin-relative paths.

**WHY:** `${CLAUDE_PLUGIN_ROOT}` resolves to plugin installation directory at runtime, supporting multiple installation
locations.

### timeout

**Type:** Number
**Unit:** Seconds
**Default:** 60 seconds (configurable per hook)

**Recommended values:**

```json
"timeout": 5      // PreToolUse validation (fast checks recommended)
"timeout": 10     // PostToolUse processing (file operations)
"timeout": 30     // SessionStart initialization
```

**Agent Decision Tree:**

```
Hook type:
├─ PreToolUse → timeout: 1-5 (fast validation recommended for responsiveness)
├─ PostToolUse → timeout: 5-10 (file processing acceptable)
└─ SessionStart → timeout: 10-30 (initialization allowed)
```

**WHY short timeouts recommended:** Hooks execute synchronously before tool execution. Long timeouts degrade agent
responsiveness. Use the minimum timeout needed for your validation logic.

### description

**Type:** String
**Max length:** Recommended <100 characters

**Good descriptions:**

```json
"description": "Validate Bash commands before execution"
"description": "Block write operations to protected directories"
"description": "Auto-format Python files after editing"
```

**Bad descriptions:**

```json
"description": "Hook"                    // ❌ Too vague
"description": "Does stuff"              // ❌ Not specific
```

**Agent Requirements:**

- Use active voice
- Be specific about what hook does
- Mention tool if relevant

## Stdin Input Format

**Hooks receive JSON via stdin with tool information.**

### Bash Tool Input

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status",
    "timeout": 120000,
    "cwd": "/path/to/directory"
  }
}
```

**Extract command:**

```python
data = json.load(sys.stdin)
cmd = data["tool_input"]["command"]
```

### Write Tool Input

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "File contents..."
  }
}
```

**Extract file path:**

```python
file_path = data["tool_input"]["file_path"]
```

### Edit Tool Input

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "old_string": "Original text",
    "new_string": "Replacement text"
  }
}
```

**Extract edit details:**

```python
file_path = data["tool_input"]["file_path"]
old_string = data["tool_input"]["old_string"]
new_string = data["tool_input"]["new_string"]
```

## Exit Code Behavior

### PreToolUse Exit Codes

- `0` — Allow tool execution (continue normally)
- `2` — Block tool execution (show error from stderr to user)
- Other — Treated as error, allow for safety (fail-open)

**Agent Implementation:**

```python
# Allow
sys.exit(0)

# Block with error message
sys.stderr.write("❌ Error message\n")
sys.exit(2)

# On exception (fail-open for safety)
except Exception:
    sys.exit(0)
```

### PostToolUse Exit Codes

**Exit codes ignored** (tool already executed, hook is post-processing only).

### Session Event Exit Codes

**Exit codes ignored** (informational hooks, not blocking).

## Advanced Hook Output (JSON)

**For exit code 0**, hooks can optionally output structured JSON for advanced control:

```json
{
  "continue": true,
  "stopReason": "Optional message when stopping",
  "suppressOutput": false,
  "systemMessage": "Optional warning shown to Claude",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Command is safe",
    "updatedInput": {
      "command": "modified-command --with-flag"
    }
  }
}
```

### Output Fields Reference

| Field                | Type    | Purpose                            |
|----------------------|---------|------------------------------------|
| `continue`           | boolean | Whether to continue execution      |
| `stopReason`         | string  | Message when stopping              |
| `suppressOutput`     | boolean | Hide hook output from verbose mode |
| `systemMessage`      | string  | Warning/info shown to Claude       |
| `hookSpecificOutput` | object  | Event-specific control             |

### hookSpecificOutput for PreToolUse

**Key capability:** Modify tool parameters before execution with `updatedInput`.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Auto-approved safe command",
    "updatedInput": {
      "command": "rg pattern file.txt"
    }
  }
}
```

| Field                      | Values                       | Purpose                      |
|----------------------------|------------------------------|------------------------------|
| `permissionDecision`       | `"allow"`, `"deny"`, `"ask"` | Override permission behavior |
| `permissionDecisionReason` | string                       | Reason shown to user         |
| `updatedInput`             | object                       | **Modified tool parameters** |

**Example: Auto-fix legacy commands**

```python
#!/usr/bin/env python3
import json
import sys

data = json.load(sys.stdin)
cmd = data.get('tool_input', {}).get('command', '')

# Auto-replace grep with rg
if cmd.startswith('grep '):
    new_cmd = cmd.replace('grep ', 'rg ', 1)
    output = {
        "continue": True,
        "systemMessage": "Auto-converted grep to rg",
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {"command": new_cmd}
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
```

**Agent Usage:**

- Use `updatedInput` to transform commands (e.g., add flags, fix paths)
- Use `permissionDecision` to auto-approve known-safe patterns
- Use `systemMessage` to inform Claude of modifications

## Environment Variables

### ${CLAUDE_PLUGIN_ROOT}

**Value:** Absolute path to plugin installation directory

**Available in:** hooks.json for referencing plugin files

**Example:**

```json
"command": "${CLAUDE_PLUGIN_ROOT}/scripts/validator.py"
```

**Resolves to:**

```
/Users/user/.claude/plugins/my-plugin/scripts/validator.py
```

**Agent Action:** Use this variable for ALL script paths in hooks.json.

## Common Configuration Patterns

### Pattern 1: Single PreToolUse Hook (Most Common)

**Use case:** Enforce standards on one tool type

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/enforcer.py",
            "timeout": 1,
            "description": "Enforce coding standards"
          }
        ]
      }
    ]
  }
}
```

**Examples:** modern-cli-enforcer, python-manager-enforcer, native-timeout-enforcer

### Pattern 2: Multiple Tool Matchers

**Use case:** Different validation for different tools

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/bash-validator.py",
            "timeout": 1,
            "description": "Validate Bash commands"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/write-validator.py",
            "timeout": 1,
            "description": "Validate file writes"
          }
        ]
      }
    ]
  }
}
```

**Agent Action:** Create separate matcher blocks for each tool type with different validation logic.

### Pattern 3: Chained Hooks (Same Tool)

**Use case:** Multiple validation steps for same tool

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/security-check.py",
            "timeout": 1,
            "description": "Security validation"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/style-check.py",
            "timeout": 1,
            "description": "Style validation"
          }
        ]
      }
    ]
  }
}
```

**Execution order:** Hooks run sequentially. If first hook blocks (exit 2), second hook doesn't run.

### Pattern 4: Pre + Post Hooks

**Use case:** Validate before, process after

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-write.py",
            "timeout": 1,
            "description": "Validate file write"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-file.py",
            "timeout": 5,
            "description": "Auto-format written file"
          }
        ]
      }
    ]
  }
}
```

**Agent Usage:** Use when action must happen AFTER tool completes (formatting, logging, cleanup).

### Pattern 5: Session Initialization

**Use case:** Load configuration on startup

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/init.sh",
            "timeout": 10,
            "description": "Initialize plugin settings"
          }
        ]
      }
    ]
  }
}
```

**Agent Usage:** Rarely needed unless plugin requires initialization state.

## Validation

### JSON Syntax Check

```bash
python3 -m json.tool hooks/hooks.json
```

**Agent Action:** Run after writing/modifying hooks.json.

### Manual Hook Testing

```bash
# Test hook script with sample input
echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' | \
  python3 scripts/validator.py
echo $?  # Check exit code (0=allow, 2=block)
```

**Agent Action:** Test hook script before integration.

## Troubleshooting Decision Trees

### Issue: Hook Not Triggering

**Investigation:**

```
Hook not intercepting commands?
├─ JSON valid?
│  └─ python3 -m json.tool hooks/hooks.json
│
├─ File in correct location?
│  └─ ls hooks/hooks.json
│
├─ Matcher matches tool?
│  └─ Check "matcher": "Bash" for Bash commands
│
├─ Script executable?
│  └─ chmod +x scripts/validator.py
│
└─ Script path correct?
   └─ Check ${CLAUDE_PLUGIN_ROOT}/scripts/...
```

### Issue: Hook Timing Out

**Investigation:**

```
Hook exceeds timeout?
├─ Timeout too short?
│  └─ Increase "timeout" value (max 60)
│
├─ Script slow?
│  └─ Optimize validation logic
│
├─ Loading too much data?
│  └─ Use lazy loading pattern
│
└─ Network calls?
   └─ Remove from PreToolUse hooks
```

### Issue: Hook Always Allows/Blocks

**Investigation:**

```
Hook not blocking/allowing correctly?
├─ Exit code correct?
│  └─ Check script exits 0 (allow) or 2 (block)
│
├─ Script has error?
│  └─ Test manually, check for exceptions
│
├─ JSON parsing working?
│  └─ echo '...' | python3 script.py
│
└─ Validation logic correct?
   └─ Review condition logic in script
```

## Agent Implementation Checklist

**When writing hooks.json:**

- [ ] Start with minimal single-hook configuration
- [ ] Use `${CLAUDE_PLUGIN_ROOT}` for all script paths
- [ ] Set appropriate timeout (1-5s for PreToolUse, 5-10s for PostToolUse)
- [ ] Add clear description
- [ ] Validate JSON syntax
- [ ] Test hook script manually with echo/pipe
- [ ] Verify matcher matches target tool
- [ ] Ensure script is executable (chmod +x)

**When adding multiple hooks:**

- [ ] Separate matchers for different tools
- [ ] Chain hooks within same matcher if validation steps related
- [ ] Use PreToolUse for validation, PostToolUse for processing
- [ ] Keep PreToolUse timeouts short (<1s ideal)

## Best Practices

### Do's ✅

**Configuration:**

- Use `${CLAUDE_PLUGIN_ROOT}` for all script paths
- Keep PreToolUse hooks fast (≤5 seconds recommended)
- Provide clear, specific descriptions
- Use forward slashes in all paths

**Structure:**

- Separate matchers for different tool types
- Chain related validation steps under same matcher
- Use PostToolUse for post-processing only

**Testing:**

- Validate JSON syntax before committing
- Test hooks manually before deployment
- Verify timeout is appropriate for hook task

### Don'ts ❌

**Configuration:**

- Don't use absolute paths for commands
- Don't use relative paths without `${CLAUDE_PLUGIN_ROOT}`
- Don't set timeout too high for PreToolUse (>5s degrades responsiveness)
- Don't skip description field

**Structure:**

- Don't list hooks.json in plugin.json (auto-loaded)
- Don't use Windows-style paths (backslashes)
- Don't assume hook will always execute (timeouts possible)

**Implementation:**

- Don't make network calls in PreToolUse hooks
- Don't perform slow operations without lazy loading
- Don't fail-closed on errors (fail-open for safety)

## See Also

- [Hook Implementation Patterns](./hook-implementation.md) — Hook script patterns and validation logic
- [Plugin Architecture](./plugin-architecture.md) — Component structure and auto-loading
- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json reference
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
