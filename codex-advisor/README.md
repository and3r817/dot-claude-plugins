# Codex Advisor Plugin

Advisory consultation skill for architectural reviews, design decisions, code analysis, and technology evaluation.

## Features

- **Chat Mode** — Peer brainstorming for exploring solutions and trade-offs
- **Consensus Mode** — Structured 7-dimension evaluation for major decisions
- **Read-only** — Advisory only, never modifies code
- **Context-aware** — Loads project constraints from CLAUDE.md

## Installation

```
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install codex-advisor@dot-claude-plugins
```

## Usage

**Trigger phrases:**

- "Consult Codex about..."
- "Get Codex's opinion on..."
- "Have Codex review..."
- "Brainstorm with Codex..."
- "Codex consensus on..."

**Example:**

```
User: "Brainstorm with Codex about our caching strategy for 50K users"
Claude: [Loads chat-mode system prompt, invokes Codex with context]
```

## Configuration

No environment variables required. Reads project constraints from `~/.claude/CLAUDE.md` automatically.

## Modes

### Chat Mode

Interactive brainstorming for trade-offs, validation, and iterative problem-solving.
See [references/chat-pattern.md](./references/chat-pattern.md)

### Consensus Mode

Structured evaluation with verdict and confidence scoring for high-stakes decisions.
See [references/consensus-pattern.md](./references/consensus-pattern.md)

## Resources

- [MCP Parameters Reference](./references/mcp-parameters.md)
- [Chat Mode System Prompt](./references/prompts/chat-mode-system-prompt.md)
- [Consensus Mode System Prompt](./references/prompts/consensus-mode-system-prompt.md)

## License

MIT
