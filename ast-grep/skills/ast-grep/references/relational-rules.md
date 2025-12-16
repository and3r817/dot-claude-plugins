# Relational Rules

Relational rules filter nodes based on their relationship to surrounding nodes.

**Core concept:** All relational rules follow the pattern:
> **target** `relates to` **surrounding**

The main rule matches the target; the relational sub-rule matches the surrounding node.

## inside

Target node must be **within** a node matching the sub-rule.

```yaml
rule:
  pattern: await $EXPR
  inside:
    kind: for_statement
    stopBy: end
```

**Use case:** Find code inside specific contexts (loops, functions, classes).

### Examples

```yaml
# await inside any loop
rule:
  pattern: await $PROMISE
  inside:
    any:
      - kind: for_statement
      - kind: for_in_statement
      - kind: while_statement
    stopBy: end

# console.log inside class methods
rule:
  pattern: console.log($$$)
  inside:
    kind: method_definition
    stopBy: end
```

---

## has

Target node must **contain** a descendant matching the sub-rule.

```yaml
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end
```

**Use case:** Find containers with specific content.

### Examples

```yaml
# Functions containing return statements
rule:
  kind: function_declaration
  has:
    kind: return_statement
    stopBy: end

# Classes with constructor
rule:
  kind: class_declaration
  has:
    kind: constructor_definition
    stopBy: end

# React components using useState
rule:
  kind: function_declaration
  has:
    pattern: useState($$$)
    stopBy: end
```

---

## precedes

Target node must appear **before** a node matching the sub-rule.

```yaml
rule:
  pattern: let $VAR
  precedes:
    pattern: $VAR = $VALUE
    stopBy: end
```

**Use case:** Find sequential patterns, declarations before usage.

### Examples

```yaml
# Variable declaration before assignment
rule:
  kind: variable_declaration
  precedes:
    kind: expression_statement
    stopBy: neighbor

# Import before export
rule:
  kind: import_statement
  precedes:
    kind: export_statement
    stopBy: end
```

---

## follows

Target node must appear **after** a node matching the sub-rule.

```yaml
rule:
  pattern: return $VALUE
  follows:
    kind: if_statement
    stopBy: neighbor
```

**Use case:** Find code that comes after specific patterns.

### Examples

```yaml
# Code after early return
rule:
  kind: expression_statement
  follows:
    pattern: return
    stopBy: neighbor

# Statement after comment
rule:
  kind: expression_statement
  follows:
    kind: comment
    stopBy: neighbor
```

---

## stopBy Option

Controls how far the search extends.

| Value      | Behavior                                    |
|------------|---------------------------------------------|
| `neighbor` | Stop at first non-matching node (default)   |
| `end`      | Search to root (`inside`) or leaves (`has`) |
| `{ rule }` | Stop when rule matches (inclusive)          |

### neighbor (default)

Searches only immediate surroundings:

```yaml
rule:
  pattern: $X
  inside:
    kind: block
    stopBy: neighbor    # Only check direct parent block
```

### end

Searches the entire tree in that direction:

```yaml
rule:
  pattern: await $EXPR
  inside:
    kind: function_declaration
    stopBy: end         # Search all ancestors up to root
```

**⚠️ Best Practice:** Always use `stopBy: end` for deep searches. Without it, rules often fail to match nested code.

### Rule Object

Stop when a specific pattern is encountered:

```yaml
rule:
  pattern: $EXPR
  inside:
    kind: function_declaration
    stopBy:
      kind: class_declaration   # Stop at class boundary
```

The `stopBy` rule is **inclusive** — if both `stopBy` and the relational rule match the same node, it's considered a
match.

---

## field Option

Specifies which field of the node to match. Only available for `inside` and `has`.

### Problem

Without `field`, matching is ambiguous:

```yaml
# This matches "prototype" as either object OR property
rule:
  regex: prototype
  inside:
    kind: member_expression
```

### Solution

Use `field` to be specific:

```yaml
# Match "prototype" only as property name
rule:
  regex: prototype
  inside:
    kind: member_expression
    field: property
```

### Common Fields

Fields depend on the language grammar. Common examples:

| Node Kind               | Common Fields                |
|-------------------------|------------------------------|
| `member_expression`     | `object`, `property`         |
| `call_expression`       | `function`, `arguments`      |
| `function_declaration`  | `name`, `parameters`, `body` |
| `assignment_expression` | `left`, `right`              |
| `binary_expression`     | `left`, `operator`, `right`  |

### Finding Field Names

Use `--debug-query=cst` to see field names:

```bash
ast-grep run --pattern 'obj.prop' --lang javascript --debug-query=cst
```

---

## Combining Relational Rules

### Multiple Relations

```yaml
rule:
  pattern: console.log($ARG)
  inside:
    kind: function_declaration
    stopBy: end
  not:
    inside:
      kind: try_statement
      stopBy: end
```

### With Composite Rules

```yaml
rule:
  all:
    - kind: await_expression
    - inside:
        any:
          - kind: for_statement
          - kind: while_statement
        stopBy: end
    - not:
        inside:
          kind: try_statement
          stopBy: end
```

---

## Common Patterns

### Find X inside Y

```yaml
rule:
  pattern: X
  inside:
    kind: Y
    stopBy: end
```

### Find Y containing X

```yaml
rule:
  kind: Y
  has:
    pattern: X
    stopBy: end
```

### Find X not inside Y

```yaml
rule:
  pattern: X
  not:
    inside:
      kind: Y
      stopBy: end
```

### Find Y containing X but not Z

```yaml
rule:
  kind: Y
  has:
    pattern: X
    stopBy: end
  not:
    has:
      pattern: Z
      stopBy: end
```
