# Chat Mode — Peer Brainstorming Pattern

This document provides the complete system prompt for Chat Mode collaboration with Codex, plus usage guidelines for
effective peer brainstorming.

## Table of Contents

- [System Prompt](#complete-system-prompt)
- [Philosophy](#chat-mode-philosophy)
- [When to Use](#when-to-use-chat-mode)
- [Effective Prompts](#effective-chat-mode-prompts)
    - [Pattern: Context + Problem + Question](#pattern-context--problem--question)
    - [Good Examples](#good-chat-prompts)
    - [Poor Examples](#poor-chat-prompts)
- [Following Up](#following-up-in-chat-mode)
- [Output Characteristics](#chat-mode-output-characteristics)
- [Presenting Results](#presenting-chat-results-to-user)
- [Best Practices](#best-practices)
- [Integration with Consensus Mode](#integration-with-consensus-mode)
- [Complete Example](#complete-invocation-example)
- [Summary](#summary)

## Complete System Prompt

**Location:** `references/prompts/chat-mode-system-prompt.md`

Load the system prompt from the file above and use it as the `developer-instructions` parameter when invoking Chat Mode.

### Optimized for GPT-5

The prompt has been optimized following OpenAI GPT-5 best practices:

- **Highly concise** using XML structure (~158 tokens, 65% reduction from original ~450)
- **No contradictions** — resolved tension between "engage deeply" and "conserve tokens"
- **Explicit stop condition** — "Conclude when sufficient clarity is achieved" for GPT-5 reasoning models
- **Concrete constraints** — "materially superior with minimal migration complexity" vs vague qualifiers
- **Consolidated directives** — 7 collaboration points merged to 5, eliminating overlaps
- **Clear sections**: line_numbers, file_requests, scope, collaboration, output

See `references/prompts/chat-mode-system-prompt.md` for the complete prompt text.

## Chat Mode Philosophy

**Peer-Level Technical Partnership**

Chat Mode positions Codex as an equal collaborator rather than a consultant. This creates:

- **Direct engagement** — No hierarchical distance, just peer-to-peer technical discussion
- **Practical focus** — Solutions grounded in actual project constraints and tech stack
- **Constructive challenge** — Respectful pushback when proposals don't align with goals
- **Concise communication** — Token-efficient, substance-over-filler responses
- **Anti-overengineering bias** — Resist unnecessary complexity and premature abstraction

## When to Use Chat Mode

✅ **Brainstorming implementation approaches** — "What's the best way to handle file uploads in our Express app?"

✅ **Exploring trade-offs** — "Should we use eager loading or N+1 query fix for this use case?"

✅ **Validating technical decisions** — "Does this caching strategy make sense given our scale?"

✅ **Discussing architecture** — "We're considering microservices split—what are the pitfalls?"

✅ **Problem-solving specific issues** — "How do we handle distributed transactions with this repository pattern?"

❌ **Formal evaluation of major decisions** — Use Consensus Mode instead

❌ **Multi-dimensional risk assessment** — Use Consensus Mode instead

❌ **High-stakes architectural reviews** — Use Consensus Mode instead

## Effective Chat Mode Prompts

### Pattern: Context + Problem + Question

**Structure:**

```
[Technical context: stack, scale, constraints] + [Problem statement] + [Specific question or exploration area]
```

**Example:**

```
We're experiencing slow dashboard load times (2-3 seconds) with 50K daily users. Current stack: Node.js + Express + PostgreSQL. Considering Redis for caching. What are the key trade-offs and potential pitfalls? What caching patterns work best for dashboards with user-specific data?
```

### Good Chat Prompts

**Brainstorming:**

```
Our API has inconsistent error handling—some endpoints return { error }, others { message }, some throw. Team prefers consistency. What's a pragmatic standardization approach? Middleware wrapper vs error classes vs response builder?
```

**Validation:**

```
Planning to use WebSockets for real-time notifications. Current setup: Express + Socket.io. 10K concurrent users expected. Should we consider scaling approach now, or add it when we hit limits? What pitfalls should we watch for?
```

**Trade-off Discussion:**

```
Debating GraphQL vs REST for new mobile API. Team has REST experience, mobile wants flexible queries. 50 existing endpoints, 6-month timeline. What are the realistic migration challenges? Is incremental adoption viable?
```

**Refactoring Strategy:**

```
Database layer tightly coupled to routes. Testing is painful. Repository pattern seems right but worried about transaction handling across repos. Given our Sequelize + PostgreSQL setup, what's the incremental path?
```

### Poor Chat Prompts

❌ **Too vague:**

```
How do I make my app faster?
```

❌ **No context:**

```
Should I use microservices?
```

❌ **Implementation request:**

```
Refactor my authentication code to use JWT instead of sessions.
```

❌ **Better suited for Consensus:**

```
Evaluate whether we should migrate our entire monolith to microservices. Analyze technical feasibility, team readiness, migration complexity, and long-term implications. Provide structured assessment with confidence scoring.
```

## Following Up in Chat Mode

Chat Mode excels at iterative refinement. Use `mcp__codex__codex-reply` to:

**Dive deeper:**

```
You mentioned eventual consistency challenges. How do we handle that in practice with our event-driven architecture?
```

**Explore alternatives:**

```
The saga pattern sounds complex for our team. What simpler alternatives exist for distributed transaction coordination?
```

**Clarify implementation:**

```
For the caching strategy you suggested—how do we handle cache invalidation when multiple services update shared data?
```

**Challenge assumptions:**

```
You recommended Redis Pub/Sub, but wouldn't that create tight coupling between services? How do we maintain loose coupling?
```

## Chat Mode Output Characteristics

Expect responses that:

- **Stay grounded** — Solutions fit within your current stack and constraints
- **Surface pitfalls** — Early warning about edge cases and failure modes
- **Present trade-offs** — Balanced perspective with pros/cons
- **Challenge respectfully** — Pushback when proposals don't align with goals
- **Provide actionable steps** — Concrete next moves, not theoretical possibilities
- **Are concise** — High signal-to-noise, minimal filler

## Presenting Chat Results to User

### Format: Conversational Synthesis

```markdown
## Codex Discussion: [Topic]

**Key Insights:**

- [Primary insight with technical reasoning]
- [Trade-off identified in current context]
- [Edge case or pitfall specific to your stack]

**Recommended Approach:**
[Codex's suggested solution with rationale grounded in your constraints]

**Alternatives:**

- **Option A:** [Brief description] — Trade-off: [key consideration]
- **Option B:** [Brief description] — Trade-off: [key consideration]

**Implementation Notes:**

- [Specific caveat or consideration]
- [Integration point or dependency to handle]

**Next Steps:**
[2-3 concrete actions to take]

Would you like to explore any aspect further, or shall I implement the recommended approach?
```

### Example Synthesis

```markdown
## Codex Discussion: Dashboard Caching Strategy

**Key Insights:**

- User-specific dashboard data requires cache invalidation on every update—standard cache-aside pattern fits well
- At 50K daily users, Redis single-instance sufficient; clustering premature
- Pitfall: Stale data during cache warming—consider cache preloading for critical users

**Recommended Approach:**
Implement cache-aside pattern with Redis for dashboard queries. Cache TTL: 5 minutes for non-critical data, on-demand
invalidation for user-triggered updates. Use Redis `HSET` for user-specific keys to enable granular invalidation.

**Alternatives:**

- **Write-through caching:** Simpler invalidation but adds latency to writes — Trade-off: consistency vs write
  performance
- **Query result caching in PostgreSQL:** No Redis dependency but less flexible — Trade-off: operational simplicity vs
  caching control

**Implementation Notes:**

- Handle Redis connection failures gracefully—degrade to direct DB queries
- Monitor cache hit rates; target >80% for dashboard endpoints
- Consider cache warming on user login for premium accounts

**Next Steps:**

1. Add Redis client to Express app with connection pooling
2. Create cache service wrapper with invalidation methods
3. Apply to top 3 slowest dashboard endpoints first

Shall I implement the Redis cache service wrapper?
```

## Best Practices

### Collaboration Quality

✅ **Provide technical context** — Stack, scale, team expertise, constraints

✅ **Be specific about problem** — Not "app is slow" but "dashboard queries take 800ms-1.2s, profiled N+1 issues"

✅ **Include constraints upfront** — Timeline, budget, team size, operational limits

✅ **Ask focused questions** — Not "what do you think?" but "what are the pitfalls with approach X?"

### Effective Follow-ups

✅ **Reference previous points** — "You mentioned saga complexity—what simpler alternatives exist?"

✅ **Explore edges** — "How does this handle service failure scenarios?"

✅ **Challenge constructively** — "Wouldn't that create tight coupling between services?"

✅ **Request specifics** — "How do we implement cache invalidation in practice?"

### Anti-Patterns

❌ **Switching to formal evaluation** — If you need structured assessment, use Consensus Mode

❌ **Requesting implementation** — Chat Mode advises; Claude implements

❌ **Vague follow-ups** — "What else?" or "Tell me more"

❌ **Ignoring constraints** — Asking about solutions that require tech not in your stack

## Integration with Consensus Mode

Use both modes complementary:

1. **Chat → Consensus:** Brainstorm approaches in Chat, then evaluate top candidates formally in Consensus
2. **Consensus → Chat:** Get formal evaluation in Consensus, then explore implementation details in Chat
3. **Chat → Decision:** For day-to-day decisions, Chat Mode alone may suffice

**Example workflow:**

```
Chat Mode: "What are pragmatic approaches to split our monolith?"
[Codex suggests 3 approaches]

Consensus Mode: "Evaluate strangler fig pattern for monolith migration. Context: [detailed proposal]"
[Codex provides structured assessment]

Chat Mode: "For the recommended strangler fig approach, how do we handle shared database access during transition?"
[Codex discusses implementation specifics]
```

## Complete Invocation Example

**Step 1: Load system prompt**
Read file `references/prompts/chat-mode-system-prompt.md` to get the complete system prompt.

**Step 2: Invoke Chat Mode**
Use `mcp__codex__codex` tool with these parameters:

- `prompt`: "We're experiencing slow dashboard load times (2-3 seconds) with 50K daily users. Current stack: Node.js +
  Express + PostgreSQL. Considering Redis for caching. What are the key trade-offs and potential pitfalls? What caching
  patterns work best for dashboards with user-specific data?"
- `developer-instructions`: [Contents from step 1]
- `sandbox`: "read-only"
- `approval-policy`: "never"
- `cwd`: "./backend"

## Summary

**Chat Mode is for:**

- Interactive brainstorming and exploration
- Practical problem-solving within constraints
- Trade-off discussions and validation
- Implementation approach refinement
- Peer-level technical partnership

**Chat Mode delivers:**

- Grounded, actionable advice
- Early pitfall identification
- Balanced trade-off analysis
- Respectful constructive challenge
- Concise, high-signal responses
- Anti-overengineering guidance

**Use when:**

- You need a technical sounding board
- Decision stakes are moderate
- You want iterative refinement
- Implementation details matter
- Practical constraints dominate
