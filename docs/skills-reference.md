# Agent Skills Reference

**Agent Context**: Read when implementing or validating agent skills. Quick reference for SKILL.md structure and skill
discovery.

## When to Consult This Document

**READ when:**

- Implementing new agent skill for plugin
- Validating SKILL.md frontmatter syntax
- Understanding skill auto-discovery mechanism
- Debugging skill not triggering
- Choosing between skill vs command vs hook

**SKIP when:**

- You already know minimal SKILL.md structure
- Working on hooks or commands (not skills)
- Only need to validate YAML syntax

## Location

**Standard path**: `skills/<skill-name>/SKILL.md`

**Auto-discovery**: Claude Code scans `skills/` directory for subdirectories containing SKILL.md

**CRITICAL**: Skills are auto-discovered. DO NOT list in plugin.json.

## Minimal Required Skill

**Start with this:**

```markdown
---
name: skill-name
description: What skill does AND when to trigger (include keywords)
allowed-tools: Read, Grep, Glob
---

# Skill Name

## Purpose
Brief overview of skill capability.

## When to Use This Skill
- Trigger condition 1
- Trigger condition 2

## Core Workflow
1. Step 1
2. Step 2
3. Step 3
```

**Agent Implementation:**

1. Create `skills/<skill-name>/SKILL.md`
2. Write frontmatter (name, description, allowed-tools required)
3. Include trigger keywords in description
4. Keep core workflow under 400 lines
5. Move details to `references/` if needed

## Frontmatter Fields Reference

### Required Fields

#### name

**Type:** String
**Format:** `lowercase-with-hyphens`

**Validation Rules:**

- MUST match parent directory name
- Lowercase letters, numbers, hyphens only
- NO spaces, underscores, or uppercase

**Valid:**

```yaml
name: github-cli
name: aws-deploy
```

**Invalid:**

```yaml
name: GitHub CLI      # ❌ Spaces, uppercase
name: aws_deploy      # ❌ Underscores
```

#### description

**Type:** String
**Max length:** 500 characters (recommend 200-300)

**CRITICAL Agent Requirements:**

- MUST include functionality description
- MUST include trigger keywords (what user might ask)
- Claude Code uses this to decide when to invoke skill
- More specific = better matching

**Good (includes trigger keywords):**

```yaml
description: GitHub CLI companion providing gh command usage patterns, security guidance, and workflow automation. Use when user asks about GitHub CLI, gh commands, repository management, or GitHub automation.
```

**Bad (missing trigger keywords):**

```yaml
description: Helps with GitHub  # ❌ Too vague, no trigger keywords
```

**Decision Tree for Keywords:**

```
What might user ask to trigger this skill?
├─ "How do I use gh?" → Include "gh commands", "GitHub CLI"
├─ "Deploy to AWS" → Include "AWS deployment", "CloudFormation", "ECS"
├─ "Review my code" → Include "code review", "quality check", "static analysis"
└─ "Design API" → Include "API design", "REST", "architecture"
```

#### allowed-tools

**Type:** Comma-separated string (official format) or array of strings

**Purpose:** Restrict tools skill can use during execution

**CRITICAL:** Use command-specific syntax, NOT broad permissions

**Official format (comma-separated string):**

```yaml
allowed-tools: Read, Grep, Glob, Bash(gh:*), WebFetch, WebSearch
```

**Alternative format (YAML array):**

```yaml
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(gh:*)      # Only gh commands
  - WebFetch
  - WebSearch
```

**Note:** Both formats are accepted. Comma-separated is the official format from Claude Code documentation.

**Agent Selection Guidelines:**

- List ONLY tools skill needs
- Use specific Bash syntax: `Bash(cmd:*)` not `Bash`
- Research skills: `Read`, `Grep`, `Glob`, `WebFetch`, `WebSearch`
- Implementation skills: Add `Write`, `Edit`, `Bash(tool:*)`

**Common Tool Patterns:**

**Research/Advisory Skills:**

```yaml
allowed-tools: Read, Grep, Glob, WebFetch, WebSearch
```

**Implementation Skills:**

```yaml
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(npm:*)
```

**Hybrid Skills:**

```yaml
allowed-tools: Read, Grep, Write, Edit, Bash(gh:*), WebFetch
```

## Skill Directory Structure

### Pattern 1: Simple Skill (Core Only)

**Use when:** Skill workflow fits in <400 lines, no complex data needed

```
skills/
└── skill-name/
    └── SKILL.md          # All content here
```

**Agent Implementation:** Keep all workflow in SKILL.md.

### Pattern 2: Skill with References (Progressive Disclosure)

**Use when:** Skill needs detailed patterns/examples/specs but core workflow concise

```
skills/
└── skill-name/
    ├── SKILL.md          # Core workflow <400 lines
    └── references/       # Detailed data (loaded on-demand)
        ├── patterns.md
        ├── examples.md
        └── api-spec.md
```

**Agent Workflow:**

1. Load SKILL.md (core workflow)
2. Follow workflow steps
3. Load `references/` ONLY when SKILL.md references them
4. Progressive disclosure: avoid loading all references upfront

**Reference pattern in SKILL.md:**

```markdown
## API Design Workflow
1. Analyze requirements
2. Consult `references/rest-patterns.md` for design patterns
3. Review `references/examples.md` for similar implementations
4. Generate API specification
```

**Agent Action:** Load `references/rest-patterns.md` only in step 2.

### Pattern 3: Skill with Scripts (Utilities)

**Use when:** Skill needs helper functions for processing

```
skills/
└── skill-name/
    ├── SKILL.md
    ├── references/
    │   └── data.md
    └── scripts/
        └── helper.py     # Utility functions
```

**Agent Workflow:**

1. Load SKILL.md
2. Execute workflow
3. Call scripts/ utilities when needed
4. Scripts are helpers, NOT validation hooks

**Script usage pattern:**

```markdown
## Workflow
1. Gather data from codebase
2. Process with `scripts/analyzer.py`
3. Present findings
```

## SKILL.md Structure Patterns

### Pattern 1: Advisory/Consultation Skill

**Use when:** Providing guidance, recommendations, analysis

```markdown
---
name: api-advisor
description: Advisory consultation for REST API design, architecture decisions, and best practices. Use when user asks about API design, REST patterns, or API architecture.
allowed-tools: Read, Grep, Glob, WebFetch, WebSearch
---

# API Design Advisor

## Purpose
Provide expert consultation on REST API design decisions and architectural patterns.

## When to Use This Skill
- User asks about API design approaches
- User needs architectural guidance for APIs
- User wants REST best practices
- User is designing new endpoints

## Core Workflow
1. Understand requirements via questions
2. Analyze existing API patterns in codebase (Read, Grep)
3. Research current best practices (WebFetch, WebSearch)
4. Present recommendations with:
   - Proposed approach
   - Tradeoffs analysis
   - Code examples from codebase
   - External references

## Key Considerations
- RESTful principles
- Versioning strategies
- Error handling patterns
- Authentication/authorization
- Rate limiting

## References
- `references/rest-patterns.md` - Detailed REST patterns
- `references/api-examples.md` - Real-world examples
```

**Agent Execution:**

- No file modifications
- Research-focused workflow
- Present options with tradeoffs
- Cite sources

### Pattern 2: Automation/Implementation Skill

**Use when:** Performing actions, executing workflows

```markdown
---
name: deploy-automation
description: Automated deployment workflow for staging and production environments. Use when user asks to deploy, ship to production, or automate deployments.
allowed-tools: Read, Bash(git:*), Bash(docker:*), Bash(kubectl:*), AskUserQuestion
---

# Deployment Automation

## Purpose
Automate deployment process with safety checks and rollback capabilities.

## When to Use This Skill
- User requests deployment to environment
- User asks to automate deployment
- User needs deployment workflow

## Core Workflow
1. Validate current branch and changes (git status)
2. Ask user to confirm environment (dev/staging/prod)
3. Run pre-deployment checks:
   - Tests passing
   - No uncommitted changes
   - Correct branch for environment
4. Build Docker image
5. Deploy to Kubernetes cluster
6. Verify deployment health
7. If health check fails, offer rollback

## Safety Checks
- Require explicit confirmation for production
- Verify tests pass before deployment
- Health check with timeout
- Automatic rollback on failure

## Error Handling
- If tests fail: Block deployment, show failures
- If build fails: Stop, show build logs
- If deploy fails: Rollback, restore previous version
```

**Agent Execution:**

- Executes bash commands via allowed-tools
- Uses AskUserQuestion for confirmations
- Implements safety checks
- Handles errors gracefully

### Pattern 3: Analysis/Investigation Skill

**Use when:** Investigating issues, analyzing patterns

```markdown
---
name: performance-analyzer
description: Analyze codebase for performance bottlenecks, identify slow patterns, and suggest optimizations. Use when user asks about performance, optimization, or slow code.
allowed-tools: Read, Grep, Glob, Bash(git:*)
---

# Performance Analyzer

## Purpose
Systematic performance analysis of codebase to identify bottlenecks.

## When to Use This Skill
- User reports slow performance
- User asks for optimization suggestions
- User wants performance audit
- User questions "why is X slow?"

## Core Workflow
1. Identify scope (specific file, directory, or full codebase)
2. Search for common performance anti-patterns:
   - N+1 queries (Grep for loop + query patterns)
   - Missing indexes (Read database migrations)
   - Inefficient algorithms (Read hot paths)
   - Memory leaks (Grep for resource handling)
3. Analyze findings by severity
4. Present prioritized recommendations:
   - Critical (major impact, easy fix)
   - High (major impact, complex fix)
   - Medium (moderate impact)
   - Low (minor optimization)
5. Provide code examples for fixes

## Anti-Pattern Detection
- Database: N+1, missing indexes, large result sets
- Memory: Unclosed resources, large allocations, caching issues
- CPU: Nested loops, inefficient algorithms, blocking operations
- Network: Synchronous calls, missing timeouts, no retry logic

## References
- `references/performance-patterns.md` - Common bottlenecks
- `references/optimization-examples.md` - Fix examples
```

**Agent Execution:**

- Investigation-focused (Read, Grep, Glob)
- Pattern matching for anti-patterns
- Severity-based prioritization
- Actionable recommendations

## Progressive Disclosure Model

**WHY**: Skills can be large (500+ lines). Load core workflow first, references on-demand.

**Agent Loading Sequence:**

```
1. Claude Code loads SKILL.md (core workflow)
2. Agent follows workflow steps
3. When workflow references file: Load that file
4. Continue workflow
```

**Example Workflow with References:**

**SKILL.md (400 lines):**

```markdown
## Workflow
1. Analyze requirements
2. Consult `references/patterns.md` for design patterns
3. Select appropriate pattern
4. Implement following `references/examples.md`
```

**Agent Execution:**

```
1. Read SKILL.md (400 lines loaded)
2. Execute step 1 (no additional reads)
3. Step 2 triggers: NOW read references/patterns.md (500 lines loaded)
4. Execute step 3 (no additional reads)
5. Step 4 triggers: NOW read references/examples.md (300 lines loaded)
```

**Total tokens**: 400 + 500 + 300 = 1200 lines (on-demand)
**vs loading upfront**: 400 + 500 + 300 = 1200 lines (immediately)

**Agent Benefit:** Can skip references if workflow branches away from them.

## Skill Triggering Mechanism

**How Claude Code decides to use skill:**

1. User query received
2. Claude Code matches query against skill descriptions
3. Best match(es) loaded
4. Agent follows SKILL.md workflow

**Agent Optimization:**

- Description MUST include keywords user might use
- More specific description = better matching
- Generic descriptions = poor matching

**Good Trigger Keywords:**

```yaml
description: GitHub CLI companion providing gh command usage patterns, security guidance, and workflow automation. Use when user asks about GitHub CLI, gh commands, repository management, pull requests, issues, or GitHub automation.
```

**Keywords:** "GitHub CLI", "gh command", "repository management", "pull requests", "issues", "GitHub automation"

**User queries that match:**

- "How do I create a PR with gh?"
- "Help me with GitHub CLI"
- "Automate GitHub workflow"
- "What gh commands are available?"

**Bad Trigger Keywords:**

```yaml
description: Helps with GitHub
```

**Keywords:** "GitHub" (too vague)

**User queries that match:** Unpredictable, competes with other GitHub-related skills

## Skill vs Command vs Hook Decision Tree

**Input:** User request or plugin requirement

```
What is needed?
│
├─ User-invoked action → Command
│  Example: "/deploy prod"
│  File: commands/deploy.md
│
├─ Validate/block execution → Hook
│  Example: Block legacy CLI tools
│  Files: hooks/hooks.json + scripts/validator.py
│
└─ Autonomous capability → Skill
   Example: "Help me design an API"
   File: skills/api-advisor/SKILL.md
```

**Key Differences:**

| Aspect    | Command               | Skill                                  | Hook                   |
|-----------|-----------------------|----------------------------------------|------------------------|
| Trigger   | User types `/command` | Claude Code invokes when query matches | Tool execution event   |
| Purpose   | Explicit action       | Autonomous assistance                  | Validation/enforcement |
| Discovery | Listed in `/slash`    | Auto-matched to queries                | Invisible to user      |
| Execution | On-demand             | Context-aware                          | Automatic              |

## Validation

### YAML Frontmatter Check

```bash
# Validate SKILL.md frontmatter
python3 -c "
import yaml
with open('skills/skill-name/SKILL.md') as f:
    content = f.read()
    if content.startswith('---'):
        frontmatter = content.split('---')[1]
        data = yaml.safe_load(frontmatter)
        assert 'name' in data
        assert 'description' in data
        assert 'allowed-tools' in data
        print('Valid')
"
```

**Agent Action:** Run after writing SKILL.md.

### Common Frontmatter Errors

**Missing required fields:**

```yaml
name: skill-name
# ❌ Missing description and allowed-tools
```

**Fix:** Add all required fields

```yaml
name: skill-name
description: What skill does
allowed-tools:
  - Read
```

**Broad bash permissions:**

```yaml
allowed-tools:
  - Bash  # ❌ Too broad
```

**Fix:** Use specific syntax

```yaml
allowed-tools:
  - Bash(git:*)  # ✅ Specific
  - Bash(npm:*)
```

**Name/directory mismatch:**

```
skills/api-advisor/SKILL.md
---
name: api-helper  # ❌ Doesn't match directory
```

**Fix:** Match directory name

```yaml
name: api-advisor  # ✅ Matches directory
```

## Troubleshooting Decision Trees

### Issue: Skill Not Triggering

**Investigation:**

```
Skill not activating on relevant query?
│
├─ SKILL.md exists?
│  └─ ls skills/skill-name/SKILL.md
│
├─ Frontmatter valid?
│  └─ Validate YAML (see above)
│
├─ Description includes trigger keywords?
│  └─ Check description has words from user query
│
├─ allowed-tools includes necessary tools?
│  └─ Verify workflow tools are permitted
│
└─ Name matches directory?
   └─ skills/skill-name/ → name: skill-name
```

**Fix Priority:**

1. Add trigger keywords to description
2. Validate YAML syntax
3. Ensure name matches directory
4. Verify allowed-tools complete

### Issue: Skill Execution Fails

**Investigation:**

```
Skill triggers but fails during execution?
│
├─ Tool access denied?
│  └─ Check allowed-tools includes tool used in workflow
│
├─ Reference file missing?
│  └─ Verify references/ files exist if SKILL.md references them
│
├─ Script execution fails?
│  └─ Check scripts/ executable and correct
│
└─ Timeout?
   └─ Workflow too complex, simplify or break into sub-skills
```

### Issue: Skill Not Auto-Discovered

**Investigation:**

```
Skill doesn't appear for any query?
│
├─ In skills/ directory?
│  └─ Must be skills/<name>/SKILL.md
│
├─ Directory has subdirectory?
│  └─ Must be skills/name/ not skills/SKILL.md
│
├─ File named exactly SKILL.md?
│  └─ Case-sensitive, must be uppercase
│
├─ Plugin installed?
│  └─ /plugin list shows plugin
│
└─ Listed in plugin.json?
   └─ Should NOT be (auto-discovered)
```

## Integration with Plugin Manifest

**CRITICAL:** Skills are auto-discovered. DO NOT list in plugin.json.

**WRONG:**

```json
{
  "skills": ["./skills/my-skill/SKILL.md"]  // ❌ Never do this
}
```

**CORRECT:**

```json
{
  "name": "my-plugin",
  "description": "Plugin with skills",
  "version": "1.0.0"
  // ✅ No skills field - auto-discovered from skills/ directory
}
```

**Auto-discovery verification:**

```bash
# Check plugin structure
tree -L 2 my-plugin/
my-plugin/
├── .claude-plugin/
│   └── plugin.json      # ✅ No skills field
└── skills/
    └── my-skill/
        └── SKILL.md     # ✅ Auto-discovered
```

## Agent Implementation Checklist

**Before creating skill:**

- [ ] Understand skill purpose (advisory vs implementation vs analysis)
- [ ] Identify trigger keywords users might use
- [ ] Determine required tools
- [ ] Decide if references/ needed (workflow >400 lines?)

**During creation:**

- [ ] Create skills/<skill-name>/SKILL.md
- [ ] Write frontmatter (name, description with keywords, allowed-tools)
- [ ] Keep core workflow under 400 lines
- [ ] Move detailed data to references/ if needed
- [ ] Reference files explicitly in workflow steps

**After creation:**

- [ ] Validate YAML syntax
- [ ] Verify name matches directory
- [ ] Check allowed-tools includes all workflow tools
- [ ] Test trigger by asking question with keywords
- [ ] Verify skill NOT listed in plugin.json

## Best Practices

### Do's ✅

**Description:**

- Include functionality AND trigger keywords
- Use words users would naturally ask
- Be specific (200-300 chars)
- Test by asking questions matching description

**Allowed-Tools:**

- List only required tools
- Use command-specific Bash: `Bash(git:*)`
- Research skills: Read, Grep, Glob, WebFetch, WebSearch
- Implementation skills: Add Write, Edit, Bash

**Structure:**

- Keep SKILL.md under 400 lines
- Use progressive disclosure (references/ on-demand)
- Number workflow steps clearly
- Reference files explicitly in workflow

### Don'ts ❌

**Description:**

- Don't use vague descriptions ("Helps with X")
- Don't omit trigger keywords
- Don't exceed 500 characters
- Don't copy description to frontmatter and body

**Allowed-Tools:**

- Don't grant broad Bash access
- Don't list tools skill doesn't use
- Don't omit tools workflow needs

**Structure:**

- Don't put everything in SKILL.md (>500 lines)
- Don't list skill in plugin.json
- Don't create skills/ at plugin root (use skills/<name>/)
- Don't forget YAML frontmatter delimiters

## See Also

- [Plugin Architecture](./plugin-architecture.md) — Component structure and progressive disclosure
- [Commands Reference](./commands-reference.md) — Slash commands vs skills
- [Adding a New Plugin](./adding-new-plugin.md) — Complete plugin creation workflow
- [Plugin Manifest Format](./plugin-manifest.md) — plugin.json structure (skills NOT listed)
