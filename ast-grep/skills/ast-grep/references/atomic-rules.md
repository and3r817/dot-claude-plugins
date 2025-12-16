# Atomic Rules

Atomic rules match individual AST nodes based on intrinsic properties.

## pattern

Matches nodes using code pattern with meta-variables.

### String Form

```yaml
rule:
  pattern: console.log($ARG)
```

### Object Form

For ambiguous patterns, use object form with context:

```yaml
rule:
  pattern:
    context: class A { $FIELD = $INIT }
    selector: field_definition
    strictness: relaxed
```

| Field        | Description                          |
|--------------|--------------------------------------|
| `context`    | Surrounding code for correct parsing |
| `selector`   | Target node kind within context      |
| `strictness` | Matching algorithm (see below)       |

### Strictness Levels

Control pattern matching precision:

| Level       | Description                       | Use Case                              |
|-------------|-----------------------------------|---------------------------------------|
| `cst`       | All nodes must match exactly      | Precise matching including whitespace |
| `smart`     | Skip unnamed nodes in target      | Default — most common use             |
| `ast`       | Only named AST nodes matched      | Ignore syntax details                 |
| `relaxed`   | Ignore comments and unnamed nodes | Flexible matching                     |
| `signature` | Only node kinds compared          | Type-level matching                   |

**Example:**

```yaml
rule:
  pattern:
    context: foo($BAR)
    strictness: relaxed
```

**CLI usage:**

```bash
ast-grep run --pattern 'foo($X)' --strictness relaxed --lang javascript .
```

---

## kind

Matches nodes by AST type name from tree-sitter grammar.

```yaml
rule:
  kind: function_declaration
```

### ESQuery Selectors (v0.39+)

Experimental support for CSS-like selectors:

```yaml
rule:
  kind: call_expression > identifier        # Direct child
```

| Selector | Meaning                     |
|----------|-----------------------------|
| `A > B`  | B is direct child of A      |
| `A + B`  | B is next sibling of A      |
| `A ~ B`  | B is following sibling of A |
| `A B`    | B is descendant of A        |

**Examples:**

```yaml
# Function containing identifier
kind: function_declaration identifier

# Method directly inside class body
kind: class_body > method_definition

# Statement after import
kind: import_statement + statement
```

### Finding Node Kind Names

Use `--debug-query=cst` to discover kind names:

```bash
ast-grep run --pattern 'async function test() {}' --lang javascript --debug-query=cst
```

---

## regex

Matches node text using Rust regular expressions.

```yaml
rule:
  regex: ^test_\w+$
```

### Notes

- Uses **Rust regex syntax** (not PCRE)
- Matches **entire node text** (implicit `^...$`)
- Inline flags: `(?i)pattern` for case-insensitive
- **Not a "positive" rule** — combine with `kind` or `pattern` for efficiency

### Examples

```yaml
# Match identifiers starting with underscore
rule:
  kind: identifier
  regex: ^_

# Case-insensitive match
rule:
  kind: string
  regex: (?i)error

# Match specific format
rule:
  kind: number
  regex: ^0x[0-9a-fA-F]+$
```

---

## nthChild

Matches nodes by position among siblings.

### Basic Usage

**Number** (1-based index):

```yaml
rule:
  nthChild: 1                  # First child
```

**Formula** (An+B syntax):

```yaml
rule:
  nthChild: 2n+1               # Odd positions (1, 3, 5, ...)
  nthChild: 2n                 # Even positions (2, 4, 6, ...)
  nthChild: 3n                 # Every third (3, 6, 9, ...)
```

### Object Form

```yaml
rule:
  nthChild:
    position: 2n+1
    reverse: true              # Count from end
    ofRule: # Filter siblings first
      kind: function_declaration
```

| Field      | Description                             |
|------------|-----------------------------------------|
| `position` | Number or An+B formula                  |
| `reverse`  | `true` to count from end                |
| `ofRule`   | Rule to filter siblings before counting |

### Examples

```yaml
# Last child
rule:
  nthChild:
    position: 1
    reverse: true

# Second function declaration
rule:
  nthChild:
    position: 2
    ofRule:
      kind: function_declaration
```

---

## range

Matches nodes by source code position.

```yaml
rule:
  range:
    start:
      line: 0
      column: 0
    end:
      line: 1
      column: 10
```

### Position Format

- **0-based** line and column numbers
- **Character-wise** (not byte-wise)
- `start` is **inclusive**
- `end` is **exclusive**

### Use Cases

- Match code at specific location (e.g., from editor cursor)
- Combine with other rules to filter by position
- Useful for programmatic API usage

---

## Combining Atomic Rules

Multiple atomic rules in one object create implicit AND:

```yaml
rule:
  kind: identifier
  regex: ^use
  # Matches identifiers starting with "use"
```

For explicit ordering (when using meta-variables), use `all`:

```yaml
rule:
  all:
    - kind: call_expression
    - pattern: $FUNC($$$ARGS)
```
