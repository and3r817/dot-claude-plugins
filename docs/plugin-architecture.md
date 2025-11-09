# Plugin Architecture

**Agent Context**: Read this when implementing or modifying plugins. Use as reference for structural decisions.

## When to Consult This Document

**READ when:**

- Creating new plugin (determine required structure)
- Choosing between hooks/, references/, assets/, scripts/
- Deciding plugin type (Hook, Skill, Hybrid)
- Understanding component interaction patterns

**SKIP when:**

- You already know the plugin structure needed
- Working with existing plugin (investigate actual structure instead)

## Standard Plugin Structure

Plugins use **progressive disclosure** to manage token efficiency:

```
plugin-name/
├── .claude-plugin/          # REQUIRED: Metadata
│   └── plugin.json          #   Always loaded by Claude Code
│                            #   DO NOT modify during execution
│
├── hooks/                   # Hook plugins only
│   └── hooks.json           #   Auto-loaded, defines event handlers
│
├── scripts/                 # Executable validation logic
│   └── enforce.py           #   Invoked by hooks via command
│                            #   Must parse stdin JSON
│                            #   Must exit 0 (allow) or 2 (block)
│
├── references/              # Load ONLY when hook needs decision data
│   └── patterns.md          #   NOT loaded by default
│                            #   Accessed by scripts when needed
│
├── assets/                  # Load ONLY when generating output
│   └── template.json        #   Templates for error messages
│                            #   Config file suggestions
│
├── tests/                   # REQUIRED: Validation
│   └── test-enforce.sh      #   Test positive/negative cases
│                            #   Validate error messages
│
├── commands/                # Optional user controls
│   └── status.md            #   Slash commands for plugin management
│
├── skills/                  # Skill plugins only
│   └── skill-name/          #   Auto-discovered subdirectories
│       └── SKILL.md         #   REQUIRED skill definition
│                            #   Optional: references/, scripts/
│
└── README.md                # REQUIRED: Installation/usage
```

## Progressive Disclosure: Token Efficiency Model

**WHY**: Minimize token consumption by loading components only when execution path requires them.

**Loading Sequence:**

1. **Always Loaded**: plugin.json (metadata only)
2. **On Hook Trigger**: scripts/ (execution logic)
3. **On Demand**: references/ (decision data), assets/ (templates)

**Agent Behavior:**

- DO NOT read references/ until script execution requires it
- DO NOT load assets/ until generating user-facing output
- Assume scripts/ contains minimal logic referencing external data

## Component Purpose and Agent Workflow

### scripts/ — Executable Logic

**Purpose**: Deterministic validation/parsing invoked by hooks

**Agent Investigation Pattern:**

1. Read script to understand validation flow
2. Identify external dependencies (references/, assets/)
3. Load dependencies only when execution path requires

**Implementation Constraints:**

- Parse JSON from stdin: `{"tool_name": "Bash", "tool_input": {"command": "..."}}`
- Exit 0 (allow) or 2 (block)
- Timeout: 1 second (keep logic minimal)
- Write errors to stderr

**Example Pattern:**

```python
data = json.load(sys.stdin)
command = data["tool_input"]["command"]

# Simple check first
if "forbidden" in command:
    sys.exit(2)

# Load references only if complex validation needed
with open(f"{plugin_root}/references/patterns.md") as f:
    patterns = parse_patterns(f.read())
```

### references/ — Decision Data

**Purpose**: Data that scripts validate against (NOT loaded by default)

**When Scripts Load References:**

- Complex pattern matching (regex lists, allowed commands)
- API spec validation
- Decision trees too large for hardcoding

**Agent Workflow:**

- DO NOT read references/ until script source shows it's loaded
- Assume references/ contains structured data (markdown lists, JSON schemas)
- If implementing hook: load references only in execution path that needs it

**Token Efficiency:**

- scripts/ (200 lines) loaded on every hook trigger
- references/ (2000 lines) loaded only when script execution reaches validation logic

### assets/ — Output Templates

**Purpose**: Templates/configs used in hook output (NOT loaded during validation)

**When Scripts Load Assets:**

- Generating error messages with templates
- Suggesting configuration files
- Providing formatted suggestions

**Agent Workflow:**

- Load assets/ only when script generates user-facing output
- Assume assets/ contains templates, not validation logic

### hooks/hooks.json — Event Configuration

**Auto-loaded**: Claude Code loads automatically, DO NOT specify in plugin.json

**Agent Actions:**

- Read to understand which events trigger scripts
- Modify only when changing hook behavior
- Use `${CLAUDE_PLUGIN_ROOT}` for script paths

### skills/ — Autonomous Capabilities

**Auto-discovered**: Claude Code scans `skills/` for subdirectories with SKILL.md

**Agent Workflow:**

1. Check if query matches skill description
2. Load SKILL.md (core workflow)
3. Load references/ only when SKILL.md references them
4. Execute using allowed tools

**Structure Pattern:**

```
skills/
└── skill-name/
    ├── SKILL.md              # Core workflow (always loaded on trigger)
    ├── references/           # Load on-demand only
    │   └── api-spec.md
    └── scripts/              # Utility scripts (optional)
        └── helper.py
```

## Plugin Types: Decision Tree

### Hook Plugin (Enforcement)

**Choose when:** Need to validate/block tool execution

**Required Components:**

- ✅ hooks/hooks.json
- ✅ scripts/
- ✅ tests/
- ✅ README.md
- ✅ .claude-plugin/plugin.json

**Optional Components:**

- ⚠️ references/ (only if validation logic is complex)
- ⚠️ assets/ (only if error messages need templates)
- ❌ skills/ (enforcement ≠ autonomous capability)

**Examples:** modern-cli-enforcer, python-manager-enforcer

### Skill Plugin (Capability)

**Choose when:** Providing specialized knowledge/workflow

**Required Components:**

- ✅ skills/<skill-name>/SKILL.md
- ✅ tests/
- ✅ README.md
- ✅ .claude-plugin/plugin.json

**Optional Components:**

- ✅ references/ (domain knowledge, API specs)
- ⚠️ scripts/ (utility functions only)
- ❌ hooks/ (skills don't validate execution)

**Examples:** codex-advisor

### Hybrid Plugin

**Choose when:** Enforcement + capability + user controls

**Required Components:**

- ✅ hooks/hooks.json
- ✅ scripts/
- ✅ skills/<skill-name>/SKILL.md
- ✅ tests/
- ✅ README.md
- ✅ .claude-plugin/plugin.json

**Optional Components:**

- ✅ references/ (shared by hooks and skills)
- ✅ assets/ (templates for both)
- ✅ commands/ (user controls)

**Examples:** github-cli (guard + usage skill + status commands)

## Component Interaction: Execution Flows

### Hook Execution Flow

```
User initiates tool → Claude Code intercepts (PreToolUse)
                   → Hook triggers script via command
                   → Script parses stdin JSON
                   → Script loads references/ IF validation path requires
                   → Script exits 0 (allow) or 2 (block)
                   → Claude Code proceeds or shows error
```

**Agent Investigation Pattern:**

1. Read hooks.json to identify matcher and script path
2. Read script to understand validation logic
3. Load references/ only if script source shows dependency
4. Verify test coverage for validation paths

### Skill Execution Flow

```
User query → Claude matches skill description
          → Claude loads SKILL.md
          → Agent follows SKILL.md workflow
          → Agent loads references/ when SKILL.md references them
          → Agent executes using allowed tools
          → Agent returns results
```

**Agent Workflow:**

1. Check skill description match before loading SKILL.md
2. Load SKILL.md (core workflow only)
3. Follow progressive disclosure: load references/ on-demand
4. Execute tools within skill's allowed-tools constraints

## Implementation Constraints

### Token Budget Awareness

**Minimize reads:**

- Read plugin.json first (metadata only, ~50 tokens)
- Read scripts/ when hook triggers (~200-500 tokens)
- Read references/ only when script execution path requires (~2000+ tokens)
- Read assets/ only when generating output (~500+ tokens)

**Investigation Strategy:**

1. Start with plugin.json (understand purpose)
2. Read hooks.json or SKILL.md (understand triggers/workflow)
3. Read scripts/ (understand logic)
4. Read references/ only if scripts source shows dependency
5. Read tests/ to verify behavior

### Modification Boundaries

**Safe to Modify:**

- scripts/ (implementation logic)
- references/ (validation data)
- assets/ (templates)
- tests/ (validation coverage)

**Modify with Caution:**

- hooks.json (changes event behavior)
- SKILL.md (changes agent workflow)
- plugin.json (changes metadata/discovery)

**Never Modify During Execution:**

- .claude-plugin/plugin.json structure (Claude Code relies on this)

## Best Practices for Agent Implementation

### Progressive Disclosure Pattern

**Correct Approach:**

```
1. Read plugin.json → understand purpose
2. Read hooks.json → understand triggers
3. Read scripts/enforce.py → understand logic
4. See script references `references/patterns.md`
5. NOW read references/patterns.md
```

**Incorrect Approach:**

```
1. Read plugin.json
2. Read hooks.json
3. Read ALL files in plugin directory (wastes tokens)
4. Read scripts/enforce.py
```

### Separation of Concerns Verification

**When investigating plugin:**

1. Check scripts/ for hardcoded data
2. If validation data is hardcoded → suggest moving to references/
3. If error messages are hardcoded → suggest moving to assets/
4. Verify scripts/ contains only logic

**Benefits for Agent:**

- Faster script reads (less code)
- Update validation data without re-reading logic
- Test logic independently

### Component Selection Decision Tree

**Implementing hook:**

```
Need to validate commands?
  → Create scripts/ with validation logic

Validation logic complex (>50 patterns)?
  → Move patterns to references/

Error messages use templates?
  → Create assets/ with message templates

Otherwise:
  → Keep logic in scripts/ only
```

**Implementing skill:**

```
Need specialized knowledge?
  → Create skills/<name>/SKILL.md with core workflow

Workflow references extensive data (API specs, examples)?
  → Create references/ with data files

Need utility functions?
  → Create scripts/ with helper functions

Otherwise:
  → SKILL.md only
```

## Investigation Pattern: Understanding Existing Plugin

**Efficient Read Sequence:**

1. `cat plugin.json` — Understand type and purpose
2. `ls plugin-name/` — Identify components present
3. Choose path:
    - **Hook plugin**: Read hooks.json → Read referenced script → Read references if script loads them
    - **Skill plugin**: Read SKILL.md → Read references if SKILL references them
    - **Hybrid**: Read both hooks.json and SKILL.md → Follow dependencies

**Avoid:**

- Reading all files before understanding structure
- Reading references/ before confirming scripts load them
- Reading assets/ before confirming output generation uses them

## See Also

- [Hook Implementation Patterns](./hook-implementation.md) — Agent workflow for implementing hooks
- [Adding a New Plugin](./adding-new-plugin.md) — Agent decision trees for plugin creation
- [Plugin Manifest Format](./plugin-manifest.md) — Reference for plugin.json structure
- [Hook Configuration Format](./hook-configuration.md) — Reference for hooks.json structure
