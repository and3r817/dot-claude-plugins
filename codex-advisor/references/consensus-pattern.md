# Consensus Mode — Structured Evaluation Pattern

This document provides the complete system prompt for Consensus Mode collaboration with Codex, plus usage guidelines for
rigorous proposal evaluation.

## Table of Contents

- [System Prompt Template](#complete-system-prompt-template)
- [Stance Options](#stance-options)
    - [Neutral Stance](#neutral-stance-default)
    - [Skeptical Stance](#skeptical-stance)
    - [Supportive Stance](#supportive-stance)
    - [Security-Focused Stance](#security-focused-stance)
    - [Performance-Focused Stance](#performance-focused-stance)
    - [Pragmatic Stance](#pragmatic-stance)
- [Philosophy](#consensus-mode-philosophy)
- [When to Use](#when-to-use-consensus-mode)
- [Effective Prompts](#effective-consensus-prompts)
- [Response Structure](#consensus-mode-response-structure)
- [Presenting Results](#presenting-consensus-results-to-user)
- [Best Practices](#best-practices)
- [Integration with Chat Mode](#integration-with-chat-mode)
- [Complete Example](#complete-invocation-example)
- [Summary](#summary)

## Complete System Prompt Template

**Location:** `references/prompts/consensus-mode-system-prompt.md`

Load the system prompt template from the file above and use it as the `developer-instructions` parameter when invoking
Consensus Mode. Replace `{stance_prompt}` with your chosen stance from the Stance Options section below.

### Optimized for GPT-5

The prompt has been optimized following OpenAI GPT-5 best practices:

- **Highly concise** using XML structure (~420 tokens, 51% reduction from original ~850)
- **XML tags for navigation** — `<role>`, `<critical_constraints>`, `<evaluation_framework>`, etc.
- **Front-loaded constraints** — Critical non-negotiable rules in prominent `<critical_constraints>` section
- **Consolidated directives** — Eliminated redundant stance ethics reminders and quality overlaps
- **Explicit format requirement** — "You MUST use this exact Markdown structure"
- **Maintained all 7 dimensions** — Complete evaluation framework preserved with concise sub-bullets

The `{stance_prompt}` placeholder must be replaced with one of the stance options below.

See `references/prompts/consensus-mode-system-prompt.md` for the complete prompt template.

## Stance Options

The `{stance_prompt}` placeholder allows you to configure Consensus Mode's evaluative perspective. Choose based on the
type of assessment needed.

### Neutral Stance (Default)

Use for balanced, objective evaluation:

```
You provide balanced, objective analysis without inherent bias toward approval or caution. Present facts, trade-offs, and recommendations based purely on technical merit and project fit.
```

### Skeptical Stance

Use when proposals need rigorous scrutiny or risk assessment:

```
You approach proposals with healthy skepticism, emphasizing potential risks, implementation challenges, and hidden complexity. While remaining fair and evidence-based, you prioritize surfacing concerns that might be overlooked. You advocate for simpler alternatives when appropriate, but acknowledge genuine innovation when present.
```

### Supportive Stance

Use when team needs confidence building or validation:

```
You approach proposals with supportive optimism, highlighting strengths, opportunities, and pathways to success. While remaining honest about challenges, you emphasize actionable solutions and frame obstacles as solvable problems. You look for ways to make ideas work, but still call out fundamental flaws when present.
```

### Security-Focused Stance

Use for security-critical evaluations:

```
You evaluate proposals through a security-first lens, prioritizing threat modeling, attack surface analysis, and compliance considerations. You emphasize defense-in-depth, principle of least privilege, and secure-by-default patterns. You flag security anti-patterns aggressively while acknowledging usability trade-offs.
```

### Performance-Focused Stance

Use for performance-critical systems:

```
You evaluate proposals through a performance-first lens, prioritizing scalability, latency, throughput, and resource efficiency. You emphasize profiling, benchmarking, and data-driven optimization. You flag performance anti-patterns and premature optimization equally, advocating for measured approaches backed by metrics.
```

### Pragmatic Stance

Use for resource-constrained environments:

```
You evaluate proposals through a pragmatic lens, balancing ideal solutions against real-world constraints of time, budget, and team capacity. You prioritize working software over perfect architecture, incremental improvement over big rewrites, and maintainability over cleverness. You advocate for "good enough" solutions that deliver value quickly while remaining honest about technical debt incurred.
```

## Consensus Mode Philosophy

**Structured Multi-Dimensional Assessment**

Consensus Mode provides rigorous evaluation across 7 dimensions with:

- **Consistent structure** — Verdict → Analysis → Confidence → Takeaways
- **Evidence-based reasoning** — Grounded in project specifics, not generalities
- **Balanced perspective** — Strengths and weaknesses objectively presented
- **Confidence transparency** — Explicit scoring of assessment certainty
- **Actionable output** — Key takeaways drive next steps
- **Stance flexibility** — Configurable perspective while maintaining integrity

## When to Use Consensus Mode

✅ **Major architectural decisions** — Microservices migration, database technology choice, framework adoption

✅ **Strategic technology evaluation** — GraphQL vs REST, monolith vs microservices, SQL vs NoSQL

✅ **Security and compliance reviews** — Authentication redesign, data handling approach, regulatory compliance

✅ **High-stakes refactoring** — Large-scale codebase restructuring, API redesign, system rewrites

✅ **Formal proposal validation** — Design documents, RFCs, architecture proposals

❌ **Quick brainstorming** — Use Chat Mode instead

❌ **Implementation details** — Use Chat Mode for iterative refinement

❌ **Day-to-day decisions** — Consensus Mode overhead not justified

## Effective Consensus Prompts

### Pattern: Proposal + Context + Evaluation Focus

**Structure:**

```
Proposal: [Clear statement of what you want to evaluate]

Context:
- [Scale: users, data, traffic]
- [Team: size, expertise, constraints]
- [Technical: stack, infrastructure, existing patterns]
- [Business: timeline, budget, compliance]

Evaluate: [Specific dimensions of concern or focus areas]
```

**Example:**

```
Proposal: Migrate our REST API to GraphQL for the new mobile app.

Context:
- 100K users, 50+ REST endpoints currently serving web and mobile
- 10-person team, strong Node.js/Express experience, no GraphQL exposure
- Infrastructure: AWS ECS, PostgreSQL, Redis caching
- Timeline: 6 months to launch mobile v2
- Mobile team requesting flexible data fetching to reduce over-fetching

Evaluate this proposal across technical feasibility, implementation complexity, team readiness, and long-term maintenance implications.
```

### Good Consensus Prompts

**Architectural Decision:**

```
Proposal: Split our monolith into microservices using domain-driven design boundaries.

Context:
- 5-year-old Node.js monolith, 200K LOC, 15 engineers
- Current pain: deployment conflicts, testing takes 45 minutes, hard to scale teams
- Infrastructure: Kubernetes available, team has limited distributed systems experience
- Business pressure: need to scale team to 30 engineers in next year

Evaluate technical feasibility, migration risks, organizational impact, and whether this solves our actual problems or creates new ones.
```

**Technology Selection:**

```
Proposal: Adopt React Server Components for our Next.js application.

Context:
- E-commerce site, 500K monthly visitors, SEO critical
- Current: Next.js 13 with client-side React, struggling with bundle size (800KB)
- Team: 8 frontend engineers, comfortable with React but not bleeding-edge
- Business: site speed impacts conversion rate (1% drop per 100ms delay)
- Timeline: Q2 2024 redesign offers opportunity for adoption

Assess technical maturity, migration complexity, performance benefits, and ecosystem stability.
```

**Security Architecture:**

```
Proposal: Implement JWT-based authentication with OAuth 2.0 for third-party integrations.

Context:
- B2B SaaS, 10K enterprise users, handling financial data
- Current: session-based auth, planning API-first architecture for mobile
- Compliance: SOC 2 Type II required, GDPR applicable
- Infrastructure: Node.js backend, PostgreSQL, considering Redis for token storage
- Third-party integrations: Salesforce, Stripe, internal analytics platform

Evaluate security posture, compliance readiness, scalability, and implementation risks.
```

### Poor Consensus Prompts

❌ **Too vague:**

```
Should we use microservices?
```

❌ **Missing context:**

```
Evaluate whether GraphQL is a good choice.
```

❌ **Better suited for Chat Mode:**

```
We're considering Redis for caching. What are some implementation approaches and pitfalls?
```

❌ **Implementation request:**

```
Design a microservices architecture for our application.
```

## Consensus Mode Response Structure

### Verdict

**Single-sentence summary** providing immediate orientation:

- "Technically sound but high implementation risk given team experience"
- "Strong user value proposition with manageable complexity"
- "Overly complex for stated problem—recommend simpler alternative"
- "Critical security gaps that must be addressed before proceeding"

### Analysis

**Detailed multi-dimensional assessment** covering:

1. Technical Feasibility — achievability, dependencies, blockers
2. Project Suitability — fit with architecture, stack, direction
3. User Value — actual benefit, comparison to alternatives
4. Implementation Complexity — challenges, effort, expertise needed
5. Alternative Approaches — simpler options, trade-offs
6. Industry Perspective — best practices, precedents, cautionary tales
7. Long-Term Implications — maintenance, scalability, evolution

### Confidence Score

**Numerical rating (1-10) with justification:**

- "8/10 - High confidence in technical assessment based on similar migrations, moderate uncertainty about timeline
  estimates"
- "5/10 - Framework is emerging; unclear ecosystem stability and production-readiness"
- "9/10 - Well-understood patterns with proven implementations at scale"

### Key Takeaways

**3-5 actionable bullets** highlighting critical insights:

- "Migration complexity underestimated—expect 9-12 months, not 6"
- "Introduce circuit breakers and distributed tracing before microservices split"
- "Pilot with non-critical service to build team experience"
- "GraphQL adds complexity without addressing core performance issue"

## Presenting Consensus Results to User

### Format: Formal Evaluation Synthesis

```markdown
## Codex Consensus Evaluation: [Proposal Title]

**Verdict:**
[Single-sentence summary from Codex]

**Analysis Highlights:**

**Technical Feasibility:** [Key findings]

- [Specific point with evidence]
- [Dependency or requirement identified]

**Implementation Complexity:** [Key findings]

- [Challenge or risk surfaced]
- [Effort/timeline estimate]

**Long-Term Implications:** [Key findings]

- [Maintenance consideration]
- [Scalability or evolution factor]

**Confidence:** [Score/10 with justification]

**Critical Takeaways:**

1. [Most important insight or recommendation]
2. [Significant risk or consideration]
3. [Alternative to consider or action to take]

**My Recommendation:**
[Claude's synthesis: proceed / modify approach / reconsider]

[Optional: specific modifications suggested or next steps]

What would you like to do?
```

### Example Synthesis

```markdown
## Codex Consensus Evaluation: GraphQL API Migration

**Verdict:**
"Technically feasible but high implementation risk for timeline given team's GraphQL inexperience and scope of existing
REST API."

**Analysis Highlights:**

**Technical Feasibility:** GraphQL migration is technically sound

- Apollo Server integrates well with existing Express/PostgreSQL stack
- Schema design can map to current REST endpoint structure
- N+1 query problem solvable with DataLoader pattern

**Implementation Complexity:** Significant challenges identified

- 50+ REST endpoints require schema design and resolver implementation
- Team has zero production GraphQL experience—steep learning curve
- Breaking changes require mobile client coordination
- Estimated 9-12 months, not 6 months

**Long-Term Implications:** Mixed outlook

- Maintenance: GraphQL schema evolution easier than REST versioning
- Performance: Requires careful N+1 optimization and query complexity limits
- Over-fetching problem solved, but introduces new caching complexity

**Confidence:** 7/10
"High confidence in technical feasibility based on similar migrations at scale, moderate uncertainty about timeline
given team experience and coordination requirements."

**Critical Takeaways:**

1. **Timeline unrealistic** — 6 months insufficient for 50-endpoint migration with zero GraphQL experience
2. **Pilot recommended** — Start with 5-10 endpoints to build team expertise before full commitment
3. **Alternative exists** — REST optimization with better client-side caching might solve over-fetching without
   migration risk
4. **Coordination critical** — Mobile and backend must stay synchronized; consider incremental adoption strategy

**My Recommendation:**
Modify approach — Implement GraphQL incrementally rather than full migration.

**Suggested Path:**

1. Pilot GraphQL for 5 new mobile-specific endpoints over 2 months
2. Evaluate team learning curve, performance gains, and mobile integration challenges
3. Decide on full migration vs hybrid REST+GraphQL based on pilot results
4. If proceeding, plan 12-month migration with mobile team coordination

This reduces risk while validating assumptions about benefits.

What would you like to do—proceed with pilot, explore REST optimization alternative, or discuss further?
```

## Best Practices

### Proposal Quality

✅ **Clear problem statement** — What are you actually trying to solve?

✅ **Comprehensive context** — Scale, team, tech, timeline, constraints

✅ **Specific evaluation ask** — Which dimensions matter most?

✅ **Alternatives considered** — Show you've explored options

### Stance Selection

✅ **Match stakes** — Skeptical for high-risk, Supportive for innovation, Neutral for most cases

✅ **Security/Performance stances** — Use for domain-critical decisions

✅ **Pragmatic stance** — Use when resource constraints dominate

### Response Handling

✅ **Extract verdict first** — Gives immediate orientation

✅ **Synthesize analysis** — Don't copy-paste; extract key insights

✅ **Present confidence** — Helps user calibrate trust in assessment

✅ **Surface takeaways** — These drive actionable next steps

### Anti-Patterns

❌ **Using for brainstorming** — Consensus overhead not needed; use Chat Mode

❌ **Vague proposals** — Codex needs specifics to evaluate meaningfully

❌ **Ignoring confidence scores** — Low confidence signals need for more info

❌ **Skipping alternatives** — Missing opportunity for better approaches

## Integration with Chat Mode

Consensus and Chat modes complement each other:

### Sequential Usage

**Consensus → Chat:**

```
1. Consensus: "Evaluate microservices migration proposal"
   [Get structured 7-dimension assessment]

2. Chat: "For the incremental migration strategy recommended, how do we handle shared database access during transition?"
   [Explore implementation specifics]
```

**Chat → Consensus:**

```
1. Chat: "What are pragmatic approaches to improve API performance?"
   [Brainstorm 3 approaches: caching, database optimization, API redesign]

2. Consensus: "Evaluate API gateway with edge caching proposal. Context: [detailed proposal from Chat brainstorming]"
   [Formal assessment of chosen approach]
```

### Parallel Usage

For major decisions, use both perspectives:

```
Consensus with Skeptical Stance: Surfaces risks and challenges
Consensus with Supportive Stance: Identifies strengths and opportunities
Chat Mode: Explores implementation pragmatics

Synthesize all three for balanced, actionable decision
```

## Complete Invocation Example

**Step 1: Load system prompt template**
Read file `references/prompts/consensus-mode-system-prompt.md` to get the template.

**Step 2: Select stance**
Choose neutral stance: "You provide balanced, objective analysis without inherent bias toward approval or caution.
Present facts, trade-offs, and recommendations based purely on technical merit and project fit."

**Step 3: Replace placeholder**
Replace `{stance_prompt}` in the template with the stance text from step 2.

**Step 4: Invoke Consensus Mode**
Use `mcp__codex__codex` tool with these parameters:

- `prompt`: "Proposal: Migrate our REST API to GraphQL for the new mobile app.\n\nContext:\n- 100K users, 50+ REST
  endpoints currently serving web and mobile\n- 10-person team, strong Node.js/Express experience, no GraphQL
  exposure\n- Infrastructure: AWS ECS, PostgreSQL, Redis caching\n- Timeline: 6 months to launch mobile v2\n- Mobile
  team requesting flexible data fetching to reduce over-fetching\n\nEvaluate this proposal across technical feasibility,
  implementation complexity, team readiness, and long-term maintenance implications."
- `developer-instructions`: [Modified template from step 3]
- `sandbox`: "read-only"
- `approval-policy`: "never"
- `model`: "gpt-5-codex"

## Summary

**Consensus Mode is for:**

- Structured evaluation of major proposals
- Multi-dimensional risk and feasibility assessment
- High-stakes architectural and technology decisions
- Formal validation with confidence scoring
- Security, performance, and compliance reviews

**Consensus Mode delivers:**

- Consistent 4-part structure (Verdict/Analysis/Confidence/Takeaways)
- Evidence-based multi-dimensional assessment
- Transparent confidence levels
- Actionable key insights
- Configurable perspective via stance selection

**Use when:**

- Decision stakes are high
- Comprehensive evaluation needed
- Multiple dimensions must be assessed
- Confidence transparency matters
- Formal documentation required
