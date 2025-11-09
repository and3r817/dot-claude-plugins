# Adding a New Plugin: Agent Decision Trees

**Agent Context**: Read when creating new plugin. Provides decision trees for component selection and implementation
workflow.

## When to Consult This Document

**READ when:**

- User requests "create plugin" or "implement plugin"
- Determining plugin structure (Hook, Skill, Hybrid)
- Choosing components (hooks/, scripts/, references/, skills/)
- Understanding implementation order

**SKIP when:**

- Modifying existing plugin (investigate actual structure instead)
- Implementing single component (consult hook-implementation.md or plugin-architecture.md)

## Prerequisites Knowledge

**MUST understand before proceeding:**

- [Plugin Architecture](./plugin-architecture.md) — Component structure, progressive disclosure
- [Hook Implementation](./hook-implementation.md) — Hook patterns (if implementing hooks)
- [Testing Guide](../TESTING.md) — Test framework usage

**If unfamiliar:** Read architecture docs first to understand component purpose.

---

## Decision Tree: Plugin Type Selection

**Input:** User request describing desired functionality

**Decision Flow:**

```
Does it validate/block tool execution?
├─ YES → Hook Plugin (enforcement)
│  └─ Requires: hooks/, scripts/, tests/
│
├─ NO → Provides specialized knowledge/workflow?
│  ├─ YES → Skill Plugin (capability)
│  │  └─ Requires: skills/, references/, tests/
│  │
│  └─ NO → User-invoked action?
│     ├─ YES → Command Plugin
│     │  └─ Requires: commands/, tests/
│     │
│     └─ Combines multiple above?
│        └─ YES → Hybrid Plugin
│           └─ Requires: All applicable components
```

**Examples:**

| User Request                    | Plugin Type | Rationale                      |
|---------------------------------|-------------|--------------------------------|
| "Block raw SQL queries"         | Hook        | Validates/blocks execution     |
| "Help me design REST APIs"      | Skill       | Specialized knowledge/workflow |
| "Command to show git status"    | Command     | User-invoked action            |
| "GitHub CLI guard + usage help" | Hybrid      | Enforcement + capability       |

---

## Component Selection Decision Tree

**Input:** Plugin type from above

### Hook Plugin Components

**Required:**

```
✅ .claude-plugin/plugin.json   (metadata)
✅ hooks/hooks.json              (hook configuration)
✅ scripts/validator.py          (validation logic)
✅ tests/test-*.sh               (test suite)
✅ README.md                     (documentation)
```

**Optional (decide based on complexity):**

```
Validation logic has >50 patterns?
├─ YES → ✅ references/ (external pattern data)
└─ NO  → ❌ Keep patterns in script

Error messages templated?
├─ YES → ✅ assets/ (message templates)
└─ NO  → ❌ Hardcode in script

User needs controls?
├─ YES → ✅ commands/ (enable/disable/status)
└─ NO  → ❌ No user controls needed
```

**Examples:** modern-cli-enforcer, python-manager-enforcer, native-timeout-enforcer

### Skill Plugin Components

**Required:**

```
✅ .claude-plugin/plugin.json        (metadata)
✅ skills/<skill-name>/SKILL.md      (skill definition)
✅ references/                       (supporting documentation)
✅ tests/test-*.sh                   (test suite)
✅ README.md                         (documentation)
```

**Optional:**

```
Skill needs utility functions?
├─ YES → ✅ scripts/ (helper functions)
└─ NO  → ❌ No scripts needed

User needs controls?
├─ YES → ✅ commands/ (status/configuration)
└─ NO  → ❌ No user controls needed
```

**DO NOT include:**

```
❌ hooks/ (skills don't validate execution)
```

**Examples:** codex-advisor

### Hybrid Plugin Components

**Required:**

```
✅ .claude-plugin/plugin.json
✅ hooks/hooks.json              (if enforcement)
✅ scripts/                      (hook validation + utilities)
✅ skills/<skill-name>/SKILL.md  (if capability)
✅ references/                   (shared data)
✅ tests/test-*.sh
✅ README.md
```

**Optional:**

```
✅ assets/     (templates for hooks + skills)
✅ commands/   (user controls)
```

**Examples:** github-cli (security guard + usage skill + status commands)

---

## Implementation Workflow

**Agent Execution Order:**

### Phase 1: Structure Creation

**Objective:** Create minimal required directory structure

**Decision:** Based on plugin type from decision tree

```bash
# Base structure (all plugins)
mkdir -p my-plugin/{.claude-plugin,tests}

# Hook plugin additions
mkdir -p my-plugin/{hooks,scripts}

# Skill plugin additions
mkdir -p my-plugin/{skills/skill-name,references}

# Optional (only if component decision tree says YES)
mkdir -p my-plugin/{assets,commands}
```

**Create required files:**

```bash
# Always required
touch my-plugin/.claude-plugin/plugin.json
touch my-plugin/README.md
touch my-plugin/tests/test-my-plugin.sh

# Hook-specific
touch my-plugin/hooks/hooks.json
touch my-plugin/scripts/validator.py

# Skill-specific
touch my-plugin/skills/skill-name/SKILL.md
```

**Agent Checkpoint:**

- [ ] Directory structure matches plugin type
- [ ] No unnecessary directories created
- [ ] All required files created

### Phase 2: Manifest Implementation

**Objective:** Write plugin.json with minimal required metadata

**Minimal version (start here):**

```json
{
  "name": "my-plugin",
  "description": "What this plugin does"
}
```

**Production version (expand after testing):**

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

**CRITICAL Agent Rules:**

- ❌ DO NOT list skills in plugin.json (auto-discovered from skills/ directory)
- ❌ DO NOT list hooks.json (auto-loaded from hooks/ directory)
- ✅ Only list commands if commands/ directory exists

**Validation:**

```bash
python3 -m json.tool my-plugin/.claude-plugin/plugin.json
```

**Agent Checkpoint:**

- [ ] plugin.json validates
- [ ] No skills or hooks.json listed
- [ ] Commands listed only if commands/ exists

### Phase 3: Core Logic Implementation

**Objective:** Implement primary plugin functionality

#### For Hook Plugins

**Step 3.1: Create hooks.json**

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
            "description": "Validate command before execution"
          }
        ]
      }
    ]
  }
}
```

**Agent Actions:**

- Replace `"matcher": "Bash"` with target tool (Bash, Write, Edit, etc.)
- Use `${CLAUDE_PLUGIN_ROOT}` for script path (REQUIRED)
- Set timeout to 1 second (enforced by Claude Code)

**Step 3.2: Create validation script**

**Agent Implementation:**

1. Copy minimal pattern from [hook-implementation.md](./hook-implementation.md#core-implementation-pattern)
2. Replace tool matcher
3. Add validation logic
4. Add error message with ❌ and 💡
5. Make executable: `chmod +x scripts/validator.py`

**Validation:**

```bash
# Test manually
echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' | python3 scripts/validator.py
echo $?  # Should be 0 (allow) or 2 (block)
```

**Agent Checkpoint:**

- [ ] Script parses stdin JSON
- [ ] Script exits 0 (allow) or 2 (block)
- [ ] Script has fail-open exception handler
- [ ] Error messages use ❌ and 💡
- [ ] Script is executable

#### For Skill Plugins

**Step 3.1: Create SKILL.md**

**Minimal frontmatter (required):**

```markdown
---
name: skill-name
description: What skill does AND when to trigger (include keywords)
allowed-tools: Read, Grep, Glob, Bash(cmd:*)
---

# Skill Name

## Purpose
Brief overview.

## When to Use This Skill
- Trigger condition 1
- Trigger condition 2

## Core Workflow
Step-by-step instructions.

## References
- `references/detailed-guide.md` - Details
```

**Agent Requirements:**

- Description MUST include functionality AND trigger keywords
- allowed-tools MUST be minimal (only required tools)
- Use command-specific Bash syntax: `Bash(gh:*)` not `Bash`
- Keep SKILL.md under 500 lines (target 200-400)
- Use progressive disclosure: move details to references/

**Step 3.2: Create references/**

**When to create:**

- SKILL.md exceeds 400 lines
- Detailed patterns/examples needed
- API specs or extensive data

**Agent Actions:**

```bash
touch my-plugin/references/detailed-guide.md
touch my-plugin/references/examples.md
```

**Agent Checkpoint:**

- [ ] SKILL.md under 500 lines
- [ ] Frontmatter includes name, description, allowed-tools
- [ ] Description includes trigger keywords
- [ ] Progressive disclosure used (references/ for details)

#### For Command Plugins

**Step 3.1: Create command file**

```markdown
---
description: What command does (one-line)
allowed-tools: Read, Bash(git:*)
---

# Command Name

## Usage
/my-command [arguments]

## Implementation
1. Action 1
2. Action 2

## Examples
/my-command --flag
```

**Agent Checkpoint:**

- [ ] Frontmatter has description and allowed-tools
- [ ] Usage documented
- [ ] Implementation steps clear

### Phase 4: Test Suite Implementation

**Objective:** Create comprehensive test coverage

**Test suite template:**

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../scripts/validator.py"

print_section "My Plugin Tests"

# Positive tests (should pass)
print_section "Test: Allow Valid Commands"
run_test "Allow valid" \
    '{"tool_name":"Bash","tool_input":{"command":"valid"}}' \
    0 \
    "$HOOK_SCRIPT"

# Negative tests (should block)
print_section "Test: Block Invalid Commands"
run_test "Block invalid" \
    '{"tool_name":"Bash","tool_input":{"command":"invalid"}}' \
    2 \
    "$HOOK_SCRIPT"

# Edge cases
print_section "Test: Edge Cases"
run_test "Handle empty" \
    '{"tool_name":"Bash","tool_input":{"command":""}}' \
    0 \
    "$HOOK_SCRIPT"

print_section "Test Suite Complete"
```

**Required test coverage:**

- ✅ Positive cases (allow valid commands)
- ✅ Negative cases (block invalid commands)
- ✅ Edge cases (empty input, invalid JSON, non-target tool)
- ✅ Error message validation (optional 5th parameter)

**Make executable:**

```bash
chmod +x my-plugin/tests/test-my-plugin.sh
```

**Validation:**

```bash
./test-framework.sh my-plugin/tests/test-my-plugin.sh
```

**Agent Checkpoint:**

- [ ] Test suite executable
- [ ] Covers positive, negative, edge cases
- [ ] All tests pass
- [ ] Error messages validated

### Phase 5: Documentation

**Objective:** Create comprehensive README.md

**Required sections:**

```markdown
# Plugin Name
Description

## Features
- Feature list

## Installation
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install my-plugin@dot-claude-plugins

## Usage
Examples with expected behavior

## Configuration (optional)
Settings if applicable

## Troubleshooting
Common issues + solutions

## Uninstall
/plugin uninstall my-plugin

## License
MIT
```

**Agent Checkpoint:**

- [ ] Clear description
- [ ] Correct marketplace name (and3r817/dot-claude-plugins)
- [ ] Usage examples show expected behavior
- [ ] Troubleshooting section included

### Phase 6: Repository Integration

**Objective:** Integrate plugin into repository test and marketplace infrastructure

**Step 6.1: Add to test runner**

**File:** `run-all-tests.sh`

**Agent Action:** Add test suite path to TEST_SUITES array

```bash
TEST_SUITES=(
    "existing-plugin/tests/test-*.sh"
    "my-plugin/tests/test-my-plugin.sh"  # Add here
)
```

**Step 6.2: Run all tests**

```bash
./run-all-tests.sh
```

**Agent Checkpoint:**

- [ ] All tests pass (including new plugin)

**Step 6.3: Register in marketplace**

**File:** `.claude-plugin/marketplace.json`

**Agent Action:** Add plugin entry

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./my-plugin",
      "description": "Comprehensive description",
      "tags": ["tag1", "tag2", "tag3"]
    }
  ]
}
```

**Tag selection guidelines:**

- Functionality: "enforcement", "security", "automation", "advisory"
- Type: "hook", "skill", "command", "hybrid"
- Technology: "python", "github", "docker", "bash"

**Validation:**

```bash
python3 -m json.tool .claude-plugin/marketplace.json
```

**Step 6.4: Update root README**

**File:** `README.md`

**Agent Action:** Add plugin entry to plugins list

```markdown
## Plugins

- [my-plugin](./my-plugin/README.md) – Description of what it does.
```

**Agent Checkpoint:**

- [ ] Plugin in marketplace.json
- [ ] Marketplace JSON validates
- [ ] Plugin in root README.md
- [ ] All JSON files validated

---

## Validation Checklist

**Before marking implementation complete:**

### Structure Validation

- [ ] Plugin directory matches type (Hook/Skill/Hybrid)
- [ ] No unnecessary directories created
- [ ] All required files present

### Component Validation

- [ ] plugin.json validates
- [ ] plugin.json does NOT list skills or hooks.json
- [ ] hooks.json validates (if exists)
- [ ] Hook scripts executable and tested
- [ ] SKILL.md under 500 lines (if skill plugin)
- [ ] SKILL.md frontmatter complete

### Test Validation

- [ ] Test suite executable
- [ ] All tests pass individually
- [ ] All tests pass in run-all-tests.sh
- [ ] Covers positive, negative, edge cases

### Integration Validation

- [ ] Plugin in run-all-tests.sh
- [ ] Plugin in marketplace.json
- [ ] Plugin in root README.md
- [ ] All JSON files validated

### Documentation Validation

- [ ] README.md complete
- [ ] Installation instructions correct
- [ ] Usage examples clear
- [ ] Troubleshooting section present

---

## Common Implementation Patterns

### Pattern 1: Simple Enforcement Hook

**Use when:** Blocking specific command patterns

**Structure:**

```
my-plugin/
├── .claude-plugin/plugin.json
├── hooks/hooks.json
├── scripts/validator.py        (simple validation)
├── tests/test-validator.sh
└── README.md
```

**Implementation time:** ~30 minutes
**Complexity:** Low
**Examples:** native-timeout-enforcer

### Pattern 2: Complex Enforcement Hook with References

**Use when:** Validation requires >50 patterns or external data

**Structure:**

```
my-plugin/
├── .claude-plugin/plugin.json
├── hooks/hooks.json
├── scripts/validator.py        (loads references/)
├── references/
│   └── patterns.txt           (validation data)
├── tests/test-validator.sh
└── README.md
```

**Implementation time:** ~1 hour
**Complexity:** Medium
**Examples:** python-manager-enforcer, modern-cli-enforcer

### Pattern 3: Capability Skill

**Use when:** Providing specialized knowledge/workflow

**Structure:**

```
my-plugin/
├── .claude-plugin/plugin.json
├── skills/skill-name/
│   └── SKILL.md               (core workflow <500 lines)
├── references/
│   ├── detailed-guide.md
│   └── examples.md
├── tests/test-skill.sh
└── README.md
```

**Implementation time:** ~2 hours
**Complexity:** Medium-High
**Examples:** codex-advisor

### Pattern 4: Hybrid Plugin

**Use when:** Combining enforcement + capability + controls

**Structure:**

```
my-plugin/
├── .claude-plugin/plugin.json
├── hooks/hooks.json
├── scripts/guard.py
├── skills/skill-name/SKILL.md
├── references/                (shared by hooks + skills)
├── commands/status.md
├── tests/
│   ├── test-guard.sh
│   └── test-skill.sh
└── README.md
```

**Implementation time:** ~4 hours
**Complexity:** High
**Examples:** github-cli

---

## Error Handling Decision Trees

### Issue: Hook Not Triggering

**Investigation Flow:**

```
Hook not intercepting commands?
├─ Validate hooks.json syntax
│  └─ python3 -m json.tool hooks/hooks.json
│
├─ Verify matcher matches tool name
│  └─ Check "matcher": "Bash" matches actual tool
│
├─ Check script permissions
│  └─ chmod +x scripts/validator.py
│
└─ Test script manually
   └─ echo '{"tool_name":"Bash",...}' | python3 script.py
```

### Issue: Skill Not Activating

**Investigation Flow:**

```
Skill not triggering?
├─ Check description includes trigger keywords
│  └─ Update description with user's query terms
│
├─ Verify allowed-tools includes necessary tools
│  └─ Add missing tools to frontmatter
│
├─ Check YAML frontmatter syntax
│  └─ No tabs, proper --- delimiters
│
└─ Test description match
   └─ Ask question exactly matching description
```

### Issue: Tests Failing

**Investigation Flow:**

```
Tests showing red ✗?
├─ Run test individually
│  └─ ./test-framework.sh plugin/tests/test-*.sh
│
├─ Check exit codes
│  └─ Script should exit 0 or 2, not 1
│
├─ Verify JSON input format
│  └─ Match hook expectations exactly
│
└─ Test script directly
   └─ echo '...' | python3 script.py; echo $?
```

---

## Agent Implementation Best Practices

### Do's ✅

**Structure:**

- Create minimal required structure (avoid unnecessary directories)
- Use progressive disclosure (split large files to references/)
- Validate JSON after every file creation

**Implementation:**

- Copy proven patterns from existing plugins
- Test components individually before integration
- Implement fail-open exception handling in hooks

**Documentation:**

- Write README.md with clear examples
- Document configuration options
- Include troubleshooting section

**Testing:**

- Cover positive, negative, edge cases
- Validate error messages with patterns
- Test plugin installation locally before committing

### Don'ts ❌

**Structure:**

- Don't list skills in plugin.json (auto-discovered)
- Don't list hooks.json in plugin.json (auto-loaded)
- Don't create empty directories

**Implementation:**

- Don't hardcode paths (use ${CLAUDE_PLUGIN_ROOT})
- Don't exceed 500 lines in SKILL.md
- Don't use overly broad hook matchers

**Testing:**

- Don't skip edge case testing
- Don't forget to add test to run-all-tests.sh
- Don't commit without validating all JSON

---

## Investigation Pattern: Understanding Existing Plugin

**Use when:** User asks "how does X plugin work" or "create plugin like X"

**Efficient investigation sequence:**

1. **Read plugin.json** → Understand type and purpose
2. **List directory** → Identify components present
3. **Choose investigation path:**
    - **Hook plugin**: Read hooks.json → Read script → Read references if script loads them
    - **Skill plugin**: Read SKILL.md → Read references if SKILL references them
    - **Hybrid**: Investigate both paths

**Extract patterns:**

- Component structure
- Validation logic patterns
- Progressive disclosure usage
- Test coverage approach

**Reuse patterns in new plugin implementation.**

---

## See Also

- [Plugin Architecture](./plugin-architecture.md) — Component structure and progressive disclosure model
- [Hook Implementation](./hook-implementation.md) — Hook patterns and agent constraints
- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json reference
- [Hook Configuration Format](./hook-configuration.md) — hooks.json reference
- [Testing Guide](../TESTING.md) — Test framework and patterns
