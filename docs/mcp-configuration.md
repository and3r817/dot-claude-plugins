# MCP Server Configuration Reference

**Agent Context**: Read when configuring MCP (Model Context Protocol) servers for plugins. Quick reference for .mcp.json
structure.

## When to Consult This Document

**READ when:**

- Adding MCP server to plugin
- Validating .mcp.json syntax
- Understanding environment variable configuration
- Debugging MCP server connection issues
- Selecting appropriate MCP server for capability

**SKIP when:**

- You already know .mcp.json structure
- Plugin doesn't need external tool integration
- Working on hooks, skills, or commands only

## Location

**Standard path**: `.mcp.json` in plugin root

**Reference in plugin.json**: Optional

```json
{
  "mcp": "./.mcp.json"
}
```

**Note:** MCP configuration can be inline in plugin.json or separate file. Separate file preferred for multiple servers.

## Minimal MCP Configuration

**Start with this:**

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-package"],
      "env": {
        "API_KEY": "${API_KEY_ENV_VAR}"
      }
    }
  }
}
```

**Agent Implementation:**

1. Replace `server-name` with descriptive name (lowercase-hyphen)
2. Replace `server-package` with actual MCP server package
3. Configure `env` with required variables
4. Test connection after plugin installation

## MCP Server Structure

### mcpServers Object

**Type:** Object (key-value pairs)

**Keys:** Server names (used for identification)
**Values:** Server configuration objects

```json
{
  "mcpServers": {
    "github": { /* config */ },
    "postgres": { /* config */ },
    "filesystem": { /* config */ }
  }
}
```

**Agent Naming Guidelines:**

- Use lowercase-with-hyphens
- Be descriptive: `github-api` not `gh`
- Match service being connected: `postgres`, `slack`, `jira`

### Server Configuration Fields

#### command (Required)

**Type:** String

**Purpose:** Executable to run MCP server

**Common values:**

- `npx` — Node.js packages (JavaScript MCP servers)
- `uvx` — Python packages (Python MCP servers)
- `docker` — Dockerized MCP servers
- `/absolute/path/to/binary` — Custom executables

```json
{
  "command": "npx",        // Node.js
  "command": "uvx",        // Python (uv)
  "command": "docker",     // Container
  "command": "/usr/local/bin/custom-server"  // Custom
}
```

**Agent Selection:**

- JavaScript servers: `npx`
- Python servers: `uvx` (preferred) or `python`
- Custom: absolute path to executable

#### args (Required)

**Type:** Array of strings

**Purpose:** Arguments passed to command

**npx pattern (Node.js):**

```json
{
  "command": "npx",
  "args": [
    "-y",                                    // Auto-install if missing
    "@modelcontextprotocol/server-github"   // Package name
  ]
}
```

**uvx pattern (Python):**

```json
{
  "command": "uvx",
  "args": [
    "mcp-server-postgres",      // Package name
    "postgresql://localhost/db" // Connection string
  ]
}
```

**docker pattern (Container):**

```json
{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "mcp-server-image:latest"
  ]
}
```

**Agent Rules:**

- Include `-y` flag for npx (auto-install)
- Pass connection strings as arguments (PostgreSQL, MySQL)
- Use environment variables for secrets, not hardcoded args

#### cwd (Optional)

**Type:** String

**Purpose:** Set working directory for MCP server process

```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/bin/server",
  "cwd": "${CLAUDE_PLUGIN_ROOT}"
}
```

**Agent Usage:**

- Set when server needs specific working directory
- Supports `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- Useful for servers that read config files relative to cwd

**Example with cwd:**

```json
{
  "mcpServers": {
    "custom-server": {
      "command": "./bin/server",
      "args": ["--config", "config.json"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}",
      "env": {
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

#### env (Optional but Common)

**Type:** Object (key-value pairs)

**Purpose:** Environment variables for MCP server

**CRITICAL:** Use `${VAR_NAME}` syntax to reference environment variables

```json
{
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "API_KEY": "${MY_SERVICE_API_KEY}",
    "DATABASE_URL": "${DATABASE_URL}"
  }
}
```

**Agent Security Rules:**

- NEVER hardcode secrets in .mcp.json
- ALWAYS use ${VAR} syntax for sensitive data
- Reference environment variables set in user's shell
- Document required env vars in plugin README

**Good:**

```json
{
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"  // ✅ References env var
  }
}
```

**Bad:**

```json
{
  "env": {
    "GITHUB_TOKEN": "ghp_abc123..."  // ❌ Hardcoded secret
  }
}
```

## Common MCP Servers

### GitHub Integration

**Server:** `@modelcontextprotocol/server-github`

**Capabilities:** Repository management, issues, pull requests, workflows

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Required env vars:**

- `GITHUB_TOKEN` — GitHub personal access token

**Agent Usage:** Query repositories, create issues, manage PRs

### PostgreSQL Database

**Server:** `mcp-server-postgres`

**Capabilities:** Query database, schema inspection, data manipulation

```json
{
  "mcpServers": {
    "postgres": {
      "command": "uvx",
      "args": [
        "mcp-server-postgres",
        "postgresql://${DB_USER}:${DB_PASS}@localhost/${DB_NAME}"
      ],
      "env": {
        "DATABASE_URL": "postgresql://${DB_USER}:${DB_PASS}@localhost/${DB_NAME}"
      }
    }
  }
}
```

**Required env vars:**

- `DATABASE_URL` — PostgreSQL connection string
- Or: `DB_USER`, `DB_PASS`, `DB_NAME` individually

**Agent Usage:** Execute queries, inspect schema, manage data

### Filesystem Access

**Server:** `@modelcontextprotocol/server-filesystem`

**Capabilities:** Extended file operations beyond Claude Code's built-in tools

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/allowed/path"
      ]
    }
  }
}
```

**Agent Usage:** Rarely needed (Claude Code has Read/Write/Edit tools). Use for specialized file operations.

### Slack Integration

**Server:** `@modelcontextprotocol/server-slack`

**Capabilities:** Send messages, read channels, manage threads

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
      }
    }
  }
}
```

**Required env vars:**

- `SLACK_BOT_TOKEN` — Slack bot token
- `SLACK_TEAM_ID` — Slack workspace ID

**Agent Usage:** Automate Slack notifications, query channel history

### Custom MCP Server

**Pattern for custom servers:**

```json
{
  "mcpServers": {
    "custom-service": {
      "command": "/path/to/custom-server",
      "args": ["--config", "${CONFIG_PATH}"],
      "env": {
        "API_ENDPOINT": "${SERVICE_API_URL}",
        "API_KEY": "${SERVICE_API_KEY}"
      }
    }
  }
}
```

**Agent Implementation:**

- Use absolute path for custom executables
- Document all required env vars in README
- Provide installation instructions for custom server

## Environment Variable Patterns

### Variable Reference Syntax

**Format:** `${VARIABLE_NAME}`

**Claude Code expansion:**

1. Reads user's shell environment
2. Replaces `${VAR}` with actual value
3. Passes to MCP server

**Example:**

```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}"
  }
}
```

**User's shell:**

```bash
export MY_API_KEY="secret_value_123"
```

**MCP server receives:**

```
API_KEY=secret_value_123
```

### Common Environment Variables

**GitHub:**

```json
{
  "GITHUB_TOKEN": "${GITHUB_TOKEN}",
  "GITHUB_API_URL": "${GITHUB_API_URL}"  // Optional, for enterprise
}
```

**Databases:**

```json
{
  "DATABASE_URL": "${DATABASE_URL}",
  "POSTGRES_HOST": "${POSTGRES_HOST}",
  "POSTGRES_PORT": "${POSTGRES_PORT}",
  "POSTGRES_USER": "${POSTGRES_USER}",
  "POSTGRES_PASSWORD": "${POSTGRES_PASSWORD}",
  "POSTGRES_DB": "${POSTGRES_DB}"
}
```

**APIs:**

```json
{
  "API_KEY": "${SERVICE_API_KEY}",
  "API_ENDPOINT": "${SERVICE_API_URL}",
  "API_TIMEOUT": "${SERVICE_TIMEOUT}"  // Optional config
}
```

### Fallback Values

**Not supported in .mcp.json:**

```json
{
  "API_KEY": "${API_KEY:-default_value}"  // ❌ Bash syntax not supported
}
```

**Agent Action:** Document required env vars in README with setup instructions.

## Configuration Patterns

### Pattern 1: Single MCP Server

**Use when:** Plugin needs one external integration

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Agent Implementation:** Straightforward, document env var in README.

### Pattern 2: Multiple Related Servers

**Use when:** Plugin integrates multiple services

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
      }
    }
  }
}
```

**Agent Implementation:** Document all env vars, group by service in README.

### Pattern 3: Database Connection

**Use when:** Plugin needs database access

```json
{
  "mcpServers": {
    "postgres": {
      "command": "uvx",
      "args": [
        "mcp-server-postgres",
        "${DATABASE_URL}"
      ],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

**Agent Implementation:** Connection string in both args and env for compatibility.

### Pattern 4: Custom Server with Config

**Use when:** Custom MCP server needs configuration file

```json
{
  "mcpServers": {
    "custom": {
      "command": "${PLUGIN_ROOT}/bin/custom-server",
      "args": [
        "--config", "${PLUGIN_ROOT}/config/server.yaml"
      ],
      "env": {
        "API_KEY": "${CUSTOM_API_KEY}",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

**Note:** `${PLUGIN_ROOT}` may not be available. Use `${CLAUDE_PLUGIN_ROOT}` if supported, or require user to set env
var.

## Validation

### JSON Syntax Check

```bash
# Validate .mcp.json syntax
python3 -m json.tool .mcp.json

# Or with jq
jq . .mcp.json
```

**Agent Action:** Run after writing/modifying .mcp.json.

### Configuration Validation

```bash
# Check all env vars are referenced (not hardcoded)
python3 -c "
import json
import re
with open('.mcp.json') as f:
    config = json.load(f)
    for server_name, server_config in config.get('mcpServers', {}).items():
        env_vars = server_config.get('env', {})
        for key, value in env_vars.items():
            if not re.match(r'\$\{[A-Z_]+\}', value):
                print(f'Warning: {server_name}.env.{key} may contain hardcoded value')
"
```

**Agent Action:** Verify no hardcoded secrets.

### Common Configuration Errors

**Missing command:**

```json
{
  "mcpServers": {
    "github": {
      "args": ["-y", "@modelcontextprotocol/server-github"]
      // ❌ Missing "command" field
    }
  }
}
```

**Fix:** Add command field

```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"]
}
```

**Hardcoded secrets:**

```json
{
  "env": {
    "API_KEY": "sk_live_abc123..."  // ❌ Secret exposed
  }
}
```

**Fix:** Use environment variable

```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}"  // ✅ References env var
  }
}
```

**Wrong variable syntax:**

```json
{
  "env": {
    "API_KEY": "$API_KEY"  // ❌ Missing braces
  }
}
```

**Fix:** Use ${VAR} syntax

```json
{
  "env": {
    "API_KEY": "${API_KEY}"  // ✅ Correct syntax
  }
}
```

## Troubleshooting Decision Trees

### Issue: MCP Server Not Connecting

**Investigation:**

```
MCP server not available in Claude Code?
│
├─ .mcp.json exists?
│  └─ ls .mcp.json
│
├─ JSON valid?
│  └─ python3 -m json.tool .mcp.json
│
├─ Command executable available?
│  └─ which npx / which uvx
│
├─ Environment variables set?
│  └─ echo $GITHUB_TOKEN (check each required var)
│
├─ Package installed?
│  └─ npx -y @modelcontextprotocol/server-github --version
│
└─ Plugin installed?
   └─ /plugin list shows plugin
```

### Issue: Authentication Failures

**Investigation:**

```
MCP server connects but auth fails?
│
├─ Env var set in shell?
│  └─ echo $API_KEY (verify value exists)
│
├─ Env var referenced correctly?
│  └─ Check "env": {"API_KEY": "${API_KEY}"}
│
├─ Token/credential valid?
│  └─ Test credential manually with curl/CLI
│
└─ Token has required permissions?
   └─ Check service documentation for scopes
```

### Issue: Server Connection Timeout

**Investigation:**

```
MCP server times out on connection?
│
├─ Network connectivity?
│  └─ ping service-host / curl service-url
│
├─ Firewall blocking?
│  └─ Check firewall rules for service port
│
├─ Service endpoint correct?
│  └─ Verify API_ENDPOINT env var
│
└─ Server process starting?
   └─ Run command manually: npx -y server-package
```

## Integration with Plugin Manifest

**Optional field in plugin.json:**

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin with MCP integration",
  "mcp": "./.mcp.json"
}
```

**Inline configuration (alternative):**

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin with MCP integration",
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Agent Decision:**

- **Separate file (.mcp.json):** Multiple servers, complex config, shared across plugins
- **Inline (plugin.json):** Single server, simple config, plugin-specific

## README Documentation Pattern

**Agent Requirement:** Document all env vars in README.md

```markdown
## Configuration

This plugin requires the following environment variables:

### GitHub Integration

```bash
export GITHUB_TOKEN="your_github_token_here"
```

**How to get token:**

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` and `workflow` scopes
3. Copy token and add to your shell profile

### Database Access

```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
```

**Connection string format:**

```
postgresql://[user]:[password]@[host]:[port]/[database]
```

## Testing Connection

After setting environment variables, restart Claude Code and verify:

```
/plugin list  # Should show plugin installed
# Try using MCP-dependent feature
```

```

**Agent Action:** Include setup instructions for each env var.

## Agent Implementation Checklist

**Before adding MCP server:**
- [ ] Identify required external integration
- [ ] Find appropriate MCP server package
- [ ] Determine required environment variables
- [ ] Check package installation method (npx/uvx/docker)

**During configuration:**
- [ ] Create .mcp.json or add to plugin.json
- [ ] Configure command (npx/uvx/custom)
- [ ] Add args (package name, connection strings)
- [ ] Configure env with ${VAR} syntax
- [ ] Validate JSON syntax

**After configuration:**
- [ ] Document env vars in README with setup instructions
- [ ] Test server connection manually (run command directly)
- [ ] Verify no hardcoded secrets
- [ ] Add to plugin.json mcp field (if using separate file)
- [ ] Test in Claude Code after plugin installation

## Best Practices

### Do's ✅

**Security:**
- Use ${VAR} syntax for all secrets
- Document required env vars in README
- Provide setup instructions for tokens/credentials
- Never commit .env files

**Configuration:**
- Use descriptive server names (lowercase-hyphen)
- Include `-y` flag for npx (auto-install)
- Group related servers logically
- Validate JSON after every edit

**Documentation:**
- Document all env vars in README
- Provide example values (without secrets)
- Include setup instructions for each service
- List required token permissions/scopes

### Don'ts ❌

**Security:**
- Don't hardcode secrets in .mcp.json
- Don't commit .env files to git
- Don't use weak variable syntax: `$VAR` instead of `${VAR}`
- Don't skip env var documentation

**Configuration:**
- Don't use overly generic server names ("api", "db")
- Don't mix inline and separate file configs
- Don't skip JSON validation
- Don't assume env vars are set (document them)

**Structure:**
- Don't create .mcp.json if only one simple server (use inline)
- Don't use Windows-style paths (backslashes)
- Don't reference undefined env vars without docs

## See Also

- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json mcp field reference
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
- [MCP Official Documentation](https://modelcontextprotocol.io) — MCP protocol specification
- [MCP Servers Registry](https://github.com/modelcontextprotocol/servers) — Official MCP servers
