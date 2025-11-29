# ast-grep Rule Reference

Quick reference and index for ast-grep rule syntax.

## Rule File Structure

```yaml
# Required
id: rule-id
language: javascript
rule: { ... }

# Optional - Finding
constraints: { ... }           # Filter meta-variables
utils: { ... }                 # Reusable utility rules

# Optional - Patching
fix: "replacement"
transform: { ... }
rewriters: [ ... ]

# Optional - Linting
severity: warning              # hint | info | warning | error | off
message: "Explanation"
note: "Extended details"
labels: { ... }
url: "https://..."

# Optional - File Filtering
files: [ "src/**/*.ts" ]
ignores: [ "**/*.test.ts" ]

# Optional - Custom Data
metadata: { ... }
```

## Supported Languages

```
C, Cpp, CSharp, Css, Go, Html, Java, JavaScript, Kotlin,
Lua, Python, Rust, Scala, Swift, Thrift, Tsx, TypeScript
```

## Rule Categories

| Category       | Rules                                           | Purpose                         |
|----------------|-------------------------------------------------|---------------------------------|
| **Atomic**     | `pattern`, `kind`, `regex`, `nthChild`, `range` | Match individual nodes          |
| **Relational** | `inside`, `has`, `precedes`, `follows`          | Filter by position/relationship |
| **Composite**  | `all`, `any`, `not`, `matches`                  | Combine rules with logic        |

## Quick Reference

### Atomic Rules

| Rule       | Example                   | Use Case                  |
|------------|---------------------------|---------------------------|
| `pattern`  | `console.log($ARG)`       | Code pattern matching     |
| `kind`     | `function_declaration`    | AST node type             |
| `regex`    | `^test_\w+$`              | Text content (Rust regex) |
| `nthChild` | `1`, `2n+1`               | Position among siblings   |
| `range`    | `{start: {line: 0}, ...}` | Source location           |

### Relational Rules

| Rule       | Meaning                      | Key Options       |
|------------|------------------------------|-------------------|
| `inside`   | Target within another node   | `stopBy`, `field` |
| `has`      | Target contains another node | `stopBy`, `field` |
| `precedes` | Target before another        | `stopBy`          |
| `follows`  | Target after another         | `stopBy`          |

**Always use `stopBy: end` for deep searches.**

### Composite Rules

| Rule      | Behavior                                |
|-----------|-----------------------------------------|
| `all`     | AND — all must match (guarantees order) |
| `any`     | OR — at least one must match            |
| `not`     | NOT — must not match                    |
| `matches` | Reference utility rule by ID            |

### Meta-Variables

| Syntax   | Matches                           |
|----------|-----------------------------------|
| `$VAR`   | Single named node                 |
| `$$VAR`  | Single unnamed node (operators)   |
| `$$$VAR` | Zero or more nodes                |
| `$_VAR`  | Non-capturing (no equality check) |

## Detailed References

- **[atomic-rules.md](atomic-rules.md)** — pattern, kind, regex, nthChild, range
- **[relational-rules.md](relational-rules.md)** — inside, has, precedes, follows, stopBy, field
- **[composite-rules.md](composite-rules.md)** — all, any, not, matches, utils
- **[metavariables.md](metavariables.md)** — $VAR, $$VAR, $$$VAR, naming rules
- **[yaml-config.md](yaml-config.md)** — constraints, transform, fix, linting, files

## Resources

- **Playground**: https://ast-grep.github.io/playground.html
- **Rule Catalog**: https://ast-grep.github.io/catalog/
- **Official Docs**: https://ast-grep.github.io/reference/rule.html
