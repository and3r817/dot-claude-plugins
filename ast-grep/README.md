# ast-grep Skill

Structural code search using AST patterns. Translates natural language queries into ast-grep rules for precise code
matching that goes beyond simple text search.

## Installation

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install ast-grep@dot-claude-plugins
```

## What It Does

This skill helps translate natural language queries into ast-grep rules for structural code search:

- **Pattern-based search**: Find code by structure, not just text (e.g., "find async functions without error handling")
- **Rule creation**: Generate ast-grep YAML rules from descriptions
- **Debugging guidance**: Understand why patterns match or don't match
- **CLI usage**: Proper `ast-grep run` and `ast-grep scan` invocations

## Example Usage

Ask Claude:

- "Find all console.log calls inside class methods"
- "Search for async functions that don't have try-catch"
- "Write an ast-grep rule to find React useEffect without cleanup"
- "Help me understand why my ast-grep pattern isn't matching"

## Prerequisites

Install ast-grep CLI:

```bash
# macOS
brew install ast-grep

# npm
npm install -g @ast-grep/cli

# cargo
cargo install ast-grep
```

## Resources

- [ast-grep Documentation](https://ast-grep.github.io/)
- [ast-grep Playground](https://ast-grep.github.io/playground.html)

## Acknowledgments

Based on the original concept from [ast-grep/claude-skill](https://github.com/ast-grep/claude-skill) by
[Herrington Darkholme](https://github.com/HerringtonDarkholme). Skill content rewritten and expanded with reference
documentation from the [official ast-grep docs](https://ast-grep.github.io/).
