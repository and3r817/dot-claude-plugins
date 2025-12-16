# Composite Rules

Composite rules combine other rules using logical operations.

## all

Matches when **ALL** sub-rules match the same node.

```yaml
rule:
  all:
    - kind: call_expression
    - pattern: console.log($ARG)
```

### Order Guarantee

`all` **guarantees execution order** — critical when meta-variables depend on prior rules:

```yaml
rule:
  all:
    - pattern: $FUNC($$$ARGS)      # First: capture FUNC
    - has:
        pattern: $FUNC             # Then: use FUNC in sub-rule
        stopBy: end
```

Without explicit `all`, rule field order is not guaranteed.

### Examples

```yaml
# Call expression that is console.log
rule:
  all:
    - kind: call_expression
    - pattern: console.log($ARG)

# Function with both await and try-catch
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - has:
        kind: try_statement
        stopBy: end
```

### Important Distinction

A rule tests **one node** — `all` checks if that single node satisfies all conditions:

```yaml
# ❌ WRONG: No node is both number AND string
rule:
  all:
    - kind: number
    - kind: string

# ✅ CORRECT: Node has both number and string children
rule:
  all:
    - has: { kind: number }
    - has: { kind: string }
```

---

## any

Matches when **ANY** sub-rule matches.

```yaml
rule:
  any:
    - pattern: console.log($$$)
    - pattern: console.warn($$$)
    - pattern: console.error($$$)
```

### Meta-Variable Behavior

Only the **matching rule's** meta-variables are captured:

```yaml
rule:
  any:
    - pattern: let $VAR = $VAL
    - pattern: const $VAR = $VAL

# If "const x = 1" matches, $VAR and $VAL are captured
# The "let" pattern's variables are not considered
```

### Examples

```yaml
# Any console method
rule:
  any:
    - pattern: console.log($$$)
    - pattern: console.warn($$$)
    - pattern: console.error($$$)
    - pattern: console.debug($$$)

# Any loop type
rule:
  any:
    - kind: for_statement
    - kind: for_in_statement
    - kind: for_of_statement
    - kind: while_statement
    - kind: do_statement

# Variable declaration (any style)
rule:
  any:
    - pattern: var $X = $Y
    - pattern: let $X = $Y
    - pattern: const $X = $Y
```

---

## not

Matches when the sub-rule does **NOT** match.

```yaml
rule:
  pattern: console.log($ARG)
  not:
    pattern: console.log('debug')
```

### Use Cases

**Exclude specific patterns:**

```yaml
rule:
  pattern: console.$METHOD($$$)
  not:
    any:
      - pattern: console.error($$$)
      - pattern: console.warn($$$)
```

**Ensure absence of content:**

```yaml
# Functions without return statement
rule:
  kind: function_declaration
  not:
    has:
      kind: return_statement
      stopBy: end
```

**Filter by context:**

```yaml
# await not inside try-catch
rule:
  pattern: await $EXPR
  not:
    inside:
      kind: try_statement
      stopBy: end
```

### Examples

```yaml
# console.log except debug messages
rule:
  pattern: console.log($ARG)
  not:
    pattern: console.log('debug')

# Async functions without error handling
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          kind: try_statement
          stopBy: end

# Identifiers not starting with underscore
rule:
  kind: identifier
  not:
    regex: ^_
```

---

## matches

References a **utility rule** by ID for reuse.

```yaml
utils:
  is-console-call:
    any:
      - pattern: console.log($$$)
      - pattern: console.warn($$$)
      - pattern: console.error($$$)

rule:
  matches: is-console-call
  inside:
    kind: function_declaration
    stopBy: end
```

### Utility Rules

Define reusable rules in the `utils` section:

```yaml
utils:
  is-loop:
    any:
      - kind: for_statement
      - kind: while_statement
      - kind: do_statement

  is-async-context:
    any:
      - kind: function_declaration
        has:
          pattern: async
      - kind: arrow_function
        has:
          pattern: async

rule:
  pattern: await $EXPR
  inside:
    matches: is-loop
    stopBy: end
```

### Recursive Rules

`matches` enables recursive patterns:

```yaml
utils:
  nested-call:
    any:
      - pattern: $FUNC()
      - pattern: $FUNC($$$ARGS)
        has:
          matches: nested-call

rule:
  matches: nested-call
```

### Cross-Rule Reference

Reference rules from other files (when using `sgconfig.yml`):

```yaml
# In sgconfig.yml
utilDirs:
  - ./utils

# In rule file
rule:
  matches: shared-util-rule-id
```

---

## Combining Composite Rules

### Nested Logic

```yaml
rule:
  all:
    - any:
        - kind: for_statement
        - kind: while_statement
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          kind: try_statement
          stopBy: end
```

### With Relational Rules

```yaml
rule:
  all:
    - pattern: $FUNC($$$)
    - inside:
        matches: is-react-component
        stopBy: end
    - not:
        inside:
          kind: useEffect
          stopBy: end
```

---

## Implicit vs Explicit Composition

### Implicit AND (Rule Object)

Multiple fields in one object create implicit AND:

```yaml
rule:
  kind: identifier
  regex: ^use
  inside:
    kind: function_declaration
    stopBy: end
```

**⚠️ Warning:** Field order is NOT guaranteed. Use explicit `all` when order matters.

### Explicit AND (all)

```yaml
rule:
  all:
    - kind: identifier
    - regex: ^use
    - inside:
        kind: function_declaration
        stopBy: end
```

**✅ Recommended** when using meta-variables across rules.

---

## Common Patterns

### Match A but not B

```yaml
rule:
  pattern: A
  not:
    pattern: B
```

### Match A or B or C

```yaml
rule:
  any:
    - pattern: A
    - pattern: B
    - pattern: C
```

### Match A and B and C

```yaml
rule:
  all:
    - pattern: A
    - has: { pattern: B, stopBy: end }
    - has: { pattern: C, stopBy: end }
```

### Match A inside B but not inside C

```yaml
rule:
  pattern: A
  inside:
    kind: B
    stopBy: end
  not:
    inside:
      kind: C
      stopBy: end
```
