# Codex MCP Tool Parameters Reference

This document details the parameters available for the Codex MCP tools when using Codex in advisory mode with Chat and
Consensus collaboration patterns.

## Table of Contents

- [mcp__codex__codex](#mcp__codex__codex)
    - [Required Parameters](#required-parameters)
    - [Advisory Mode Parameters](#advisory-mode-parameters)
    - [Mode-Specific Parameters](#mode-specific-parameters)
    - [Optional Parameters](#optional-parameters)
- [mcp__codex__codex-reply](#mcp__codex__codex-reply)
- [Configuration Examples](#chat-mode-configuration-examples)
    - [Chat Mode Examples](#chat-mode-configuration-examples)
    - [Consensus Mode Examples](#consensus-mode-configuration-examples)
- [Advisory Mode Constraints](#advisory-mode-constraints)
- [Mode Selection Guide](#mode-selection-guide)
- [Return Values](#return-values)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)
- [Summary](#summary)

## mcp__codex__codex

Primary tool for initiating a Codex collaboration session in either Chat or Consensus mode.

### Required Parameters

**prompt** (string)

- The question, problem, or proposal to send to Codex
- **For Chat Mode:** Context + problem + specific question (see `chat-pattern.md`)
- **For Consensus Mode:** Proposal + context + evaluation focus (see `consensus-pattern.md`)
- Should be specific, include constraints, and define expected output

### Advisory Mode Parameters

**sandbox** (string) — ALWAYS use `"read-only"` for advisory sessions

- `"read-only"` — Prevents file modifications (required for advisory mode) ✅
- `"workspace-write"` — Allows file changes (DO NOT use for advisory) ❌
- `"danger-full-access"` — System-wide access (DO NOT use for advisory) ❌

**approval-policy** (string) — Use `"never"` for advisory sessions

- `"never"` — Auto-approve all commands (safe for read-only advisory) ✅
- `"untrusted"` — Approve all shell commands (unnecessary for advisory) ❌
- `"on-failure"` — Approve if command fails (unnecessary for advisory) ❌
- `"on-request"` — Approve when Codex asks (unnecessary for advisory) ❌

### Mode-Specific Parameters

**developer-instructions** (string) — REQUIRED for Chat and Consensus modes

- **For Chat Mode:** Complete chat system prompt from `chat-pattern.md`
- **For Consensus Mode:** Complete consensus system prompt with chosen stance from `consensus-pattern.md`
- This parameter configures the collaboration mode and perspective

### Optional Parameters

**cwd** (string)

- Working directory for the Codex session
- Defaults to current directory
- If relative, resolved against server process's working directory
- Example: `"/Users/<suer>/projects/my-app"` or `"./backend"`

**model** (string)

- Override the model used for collaboration
- Options: `"gpt-5-codex"`, `"gpt-5"`
- Default uses configured model
- **gpt-5-codex**: Optimized for coding tasks, refactoring, architectural analysis (scores 51.3% on code refactoring vs
  33.9% for gpt-5). Adapts thinking time dynamically based on complexity. Available in Responses API only.
- **gpt-5**: General reasoning model for non-coding logical/technical/scientific tasks
- Recommend `"gpt-5-codex"` for code-related architectural analysis and consensus evaluations

**base-instructions** (string)

- Replaces default Codex instructions entirely
- Rarely needed; use `developer-instructions` for mode configuration instead
- Only use for highly specialized customization beyond Chat/Consensus modes

**compact-prompt** (string)

- Custom prompt used when compacting conversation history
- Only relevant for long collaboration sessions with many follow-ups

**config** (object)

- Individual config settings overriding `CODEX_HOME/config.toml`
- Advanced usage only
- Example: `{"model": {"temperature": 0.7}}`

**profile** (string)

- Configuration profile from `config.toml` to specify defaults
- Allows pre-configured collaboration modes

## mcp__codex__codex-reply

Tool for continuing an existing Codex collaboration conversation.

### Required Parameters

**conversationId** (string)

- The conversation ID returned from initial `mcp__codex__codex` call
- Maintains context across collaboration exchanges
- Format: UUID string

**prompt** (string)

- Follow-up question, deeper exploration, or clarification request
- Can reference previous analysis: "Based on your recommendation..."
- Can dive deeper: "How do we handle distributed transactions in that pattern?"
- Can explore alternatives: "What's a simpler approach that avoids that complexity?"

### No Additional Parameters

Follow-up calls use the mode and configuration from the initial session. You cannot change `developer-instructions`,
`sandbox`, or other settings mid-conversation.

## Chat Mode Configuration Examples

### Basic Chat Mode Invocation

```json
{
  "prompt": "We're experiencing slow dashboard load times (2-3 seconds) with 50K daily users. Current stack: Node.js + Express + PostgreSQL. Considering Redis for caching. What are the key trade-offs and potential pitfalls? What caching patterns work best for dashboards with user-specific data?",
  "developer-instructions": "[Complete chat mode system prompt from chat-pattern.md]",
  "sandbox": "read-only",
  "approval-policy": "never"
}
```

### Chat Mode with Working Directory

```json
{
  "prompt": "Our database layer has grown tightly coupled to Express routes. Testing is difficult, and we're considering repository pattern. Given our current Sequelize ORM setup, what are practical migration approaches? What pitfalls should we watch for with incremental refactoring?",
  "developer-instructions": "[Complete chat mode system prompt from chat-pattern.md]",
  "cwd": "./backend",
  "sandbox": "read-only",
  "approval-policy": "never"
}
```

### Chat Mode Follow-Up

```json
{
  "conversationId": "550e8400-e29b-41d4-a716-446655440000",
  "prompt": "You mentioned transaction management challenges. How do we handle distributed transactions across repositories? Should we use unit of work pattern?"
}
```

## Consensus Mode Configuration Examples

### Basic Consensus Mode Invocation (Neutral Stance)

```json
{
  "prompt": "Proposal: Migrate our REST API to GraphQL for the new mobile app.\n\nContext:\n- 100K users, 50+ REST endpoints currently serving web and mobile\n- 10-person team, strong Node.js/Express experience, no GraphQL exposure\n- Infrastructure: AWS ECS, PostgreSQL, Redis caching\n- Timeline: 6 months to launch mobile v2\n- Mobile team requesting flexible data fetching to reduce over-fetching\n\nEvaluate this proposal across technical feasibility, implementation complexity, team readiness, and long-term maintenance implications.",
  "developer-instructions": "[Complete consensus mode system prompt with neutral stance from consensus-pattern.md]",
  "sandbox": "read-only",
  "approval-policy": "never",
  "model": "gpt-5-codex"
}
```

### Consensus Mode with Skeptical Stance

```json
{
  "prompt": "Proposal: Split our monolith into microservices using domain-driven design boundaries.\n\nContext:\n- 5-year-old Node.js monolith, 200K LOC, 15 engineers\n- Current pain: deployment conflicts, testing takes 45 minutes, hard to scale teams\n- Infrastructure: Kubernetes available, team has limited distributed systems experience\n- Business pressure: need to scale team to 30 engineers in next year\n\nEvaluate technical feasibility, migration risks, organizational impact, and whether this solves our actual problems or creates new ones.",
  "developer-instructions": "[Complete consensus mode system prompt with skeptical stance from consensus-pattern.md]",
  "sandbox": "read-only",
  "approval-policy": "never",
  "model": "gpt-5-codex"
}
```

### Consensus Mode with Security-Focused Stance

```json
{
  "prompt": "Proposal: Implement JWT-based authentication with OAuth 2.0 for third-party integrations.\n\nContext:\n- B2B SaaS, 10K enterprise users, handling financial data\n- Current: session-based auth, planning API-first architecture for mobile\n- Compliance: SOC 2 Type II required, GDPR applicable\n- Infrastructure: Node.js backend, PostgreSQL, considering Redis for token storage\n- Third-party integrations: Salesforce, Stripe, internal analytics platform\n\nEvaluate security posture, compliance readiness, scalability, and implementation risks.",
  "developer-instructions": "[Complete consensus mode system prompt with security-focused stance from consensus-pattern.md]",
  "sandbox": "read-only",
  "approval-policy": "never",
  "model": "gpt-5-codex"
}
```

### Consensus Mode Follow-Up

```json
{
  "conversationId": "550e8400-e29b-41d4-a716-446655440000",
  "prompt": "Based on the security concerns you identified, what specific mitigations would you recommend? Prioritize by impact and implementation complexity."
}
```

## Advisory Mode Constraints

### Safety Guarantees

When using the recommended advisory mode parameters:

✅ **read-only sandbox** — Codex cannot modify files or execute dangerous commands

✅ **never approval-policy** — No shell command interruptions (safe with read-only)

✅ **Network access enabled** — Codex can search web while maintaining read-only safety

✅ **Analysis focus** — Codex provides insights and recommendations, not implementations

### Network Access Capabilities

Codex has web search access for:

**Documentation & References:**

- Latest API documentation and framework guides
- Package versions, changelogs, migration guides
- Official best practices and architectural patterns

**Security & Compliance:**

- CVE databases and security advisories
- Compliance requirements (HIPAA, GDPR, SOC 2)
- Known vulnerabilities in dependencies

**Validation & Research:**

- Performance benchmarks and comparisons
- Technology adoption metrics and maturity
- Industry case studies and proven patterns

**When Codex Should Use Network:**

- Verifying current best practices for recent framework versions
- Checking security status of proposed dependencies
- Researching real-world implementation patterns
- Validating compliance requirements with authoritative sources

**Codex Self-Regulates:**

- Uses web search judiciously when current information adds value
- Focuses searches on technical/architectural concerns
- Avoids general browsing unrelated to consultation

### Configuration Template

Standard advisory mode configuration (applies to both Chat and Consensus):

```json
{
  "sandbox": "read-only",
  "approval-policy": "never"
}
```

Always include these parameters to ensure Codex operates purely in advisory capacity.

## Mode Selection Guide

### Use Chat Mode When:

- Brainstorming solutions interactively
- Exploring trade-offs and alternatives
- Discussing implementation pragmatics
- Seeking peer-level technical validation
- Iterative refinement of approaches
- **Model choice**: Use `gpt-5-codex` for code-related discussions, `gpt-5` for general reasoning

### Use Consensus Mode When:

- Evaluating major architectural proposals
- Assessing high-stakes technology decisions
- Requiring structured multi-dimensional analysis
- Needing confidence-scored assessments
- Documenting formal evaluations
- **Model choice**: Use `gpt-5-codex` for code/architecture evaluations

### Parameters Comparison

| Parameter                | Chat Mode                             | Consensus Mode                           |
|--------------------------|---------------------------------------|------------------------------------------|
| `prompt` style           | Context + problem + question          | Proposal + context + evaluation focus    |
| `developer-instructions` | Chat system prompt                    | Consensus system prompt + stance         |
| `model` recommendation   | `gpt-5-codex` for code, `gpt-5` other | `gpt-5-codex` for architectural analysis |
| `sandbox`                | `read-only` (required)                | `read-only` (required)                   |
| `approval-policy`        | `never` (required)                    | `never` (required)                       |

## Stance Selection for Consensus Mode

| Stance                  | When to Use                            | Example Scenario                |
|-------------------------|----------------------------------------|---------------------------------|
| **Neutral**             | Balanced objective assessment          | General architectural decisions |
| **Skeptical**           | Risk-heavy proposals, need scrutiny    | Major migrations, rewrites      |
| **Supportive**          | Innovation validation, team confidence | New technology adoption         |
| **Security-Focused**    | Security-critical systems              | Authentication, data handling   |
| **Performance-Focused** | Performance-critical systems           | High-throughput APIs, real-time |
| **Pragmatic**           | Resource-constrained environments      | Startup, tight deadlines        |

## Return Values

Both `mcp__codex__codex` and `mcp__codex__codex-reply` return:

- **Collaboration response** — Codex's analysis, recommendations, or answers formatted according to mode
- **conversationId** — UUID for follow-up collaboration (initial call only)

The response contains the advisory content that should be synthesized and presented to the user with actionable next
steps.

## Common Patterns

### Chat Mode Session

**Initial brainstorming:**
Invoke `mcp__codex__codex` tool with:

- `prompt`: "Context + problem + question"
- `developer-instructions`: [Chat system prompt contents]
- `sandbox`: "read-only"
- `approval-policy`: "never"

Store the returned `conversationId` for follow-ups.

**Follow-up exploration:**
Invoke `mcp__codex__codex-reply` tool with:

- `conversationId`: [ID from initial call]
- `prompt`: "Dive deeper into specific aspect"

**Challenge or clarify:**
Invoke `mcp__codex__codex-reply` tool with:

- `conversationId`: [same ID]
- `prompt`: "Wouldn't that create tight coupling? How to avoid?"

### Consensus Mode Session

**Initial evaluation:**
Invoke `mcp__codex__codex` tool with:

- `prompt`: "Proposal: [statement]\n\nContext:\n- [details]\n\nEvaluate: [focus]"
- `developer-instructions`: [Consensus system prompt with stance replaced]
- `sandbox`: "read-only"
- `approval-policy`: "never"
- `model`: "gpt-5-codex"

Store the returned `conversationId`.

**Clarification on specific dimension:**
Invoke `mcp__codex__codex-reply` tool with:

- `conversationId`: [ID from initial call]
- `prompt`: "Elaborate on the long-term maintenance implications you mentioned"

### Mixed Mode Workflow

**Step 1: Chat for brainstorming**
Invoke `mcp__codex__codex` tool with:

- `prompt`: "What are pragmatic approaches to improve API performance?"
- `developer-instructions`: [Chat system prompt]
- `sandbox`: "read-only"
- `approval-policy`: "never"

Review Codex's suggestions (e.g., caching, DB optimization, GraphQL).

**Step 2: Consensus for formal evaluation**
Invoke `mcp__codex__codex` tool with:

- `prompt`: "Proposal: Implement GraphQL API layer. Context: [details from chat]. Evaluate feasibility and complexity."
- `developer-instructions`: [Consensus system prompt with stance]
- `sandbox`: "read-only"
- `approval-policy`: "never"
- `model`: "gpt-5-codex"

**Step 3: Back to Chat for implementation details**
Invoke `mcp__codex__codex` tool with:

- `prompt`: "Based on GraphQL evaluation, how do we handle N+1 query problems in our specific stack?"
- `developer-instructions`: [Chat system prompt]
- `sandbox`: "read-only"
- `approval-policy`: "never"
- `model`: "gpt-5-codex"

## Best Practices

### Parameter Selection

✅ **Always read-only** — Advisory mode never requires write access

✅ **Always never approval** — Safe for read-only, eliminates interruptions

✅ **Include developer-instructions** — Required for proper mode configuration

✅ **Use gpt-5-codex for Consensus** — Code/architecture evaluations benefit from specialized model

✅ **Provide rich context** — Scale, team, tech, constraints in prompts

### Prompt Quality

✅ **Chat prompts:** Context + specific problem + focused question

✅ **Consensus prompts:** Clear proposal + comprehensive context + evaluation dimensions

✅ **Follow-ups:** Reference previous points, explore specifics, challenge constructively

### Anti-Patterns

❌ **Vague prompts** — "Should we use microservices?" without context

❌ **Wrong mode choice** — Using Consensus for quick questions, Chat for formal reviews

❌ **Missing developer-instructions** — Results in generic responses without mode structure

❌ **Write access** — Never needed for advisory sessions

## Summary

**Core Advisory Configuration:**

```json
{
  "sandbox": "read-only",
  "approval-policy": "never"
}
```

**Mode-Specific Additions:**

**Chat Mode:**

- `developer-instructions`: Chat system prompt from `chat-pattern.md`
- Prompt: Context + problem + question
- Optional: `cwd` for working directory

**Consensus Mode:**

- `developer-instructions`: Consensus system prompt + stance from `consensus-pattern.md`
- Prompt: Proposal + context + evaluation focus
- Recommended: `model: "gpt-5-codex"` for code/architecture analysis, `model: "gpt-5"` for general reasoning

Both modes maintain strict advisory boundaries while providing distinct collaboration styles optimized for different
decision contexts.
