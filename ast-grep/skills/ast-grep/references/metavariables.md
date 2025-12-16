# Meta-Variables

Meta-variables are placeholders in patterns that match dynamic content in the AST.

## $VAR — Single Named Node

Captures exactly one named AST node.

```yaml
pattern: console.log($GREETING)
# Matches: console.log("Hello")
# Captures: GREETING = "Hello"
```

### Naming Rules

| Valid     | Invalid       | Reason                 |
|-----------|---------------|------------------------|
| `$VAR`    | `$var`        | Must be uppercase      |
| `$MY_VAR` | `$my-var`     | No hyphens             |
| `$VAR1`   | `$123`        | Can't start with digit |
| `$_`      | `$kebab-case` | No special chars       |
| `$_123`   |               |                        |

**Pattern:** `$` + uppercase letters + underscores + digits

### Reuse Enforces Equality

Same meta-variable name must match identical content:

```yaml
pattern: $A == $A
# ✅ Matches: x == x, foo == foo
# ❌ Does NOT match: x == y, a == b
```

```yaml
pattern: $OBJ.$PROP = $OBJ.$PROP
# Matches: obj.x = obj.x
# Does NOT match: obj.x = obj.y
```

### Different Names = Independent

```yaml
pattern: $A == $B
# Matches: x == y (A=x, B=y)
# Matches: x == x (A=x, B=x)
```

---

## $$VAR — Single Unnamed Node

Captures a single **unnamed** (anonymous) node like operators and punctuation.

```yaml
rule:
  kind: binary_expression
  has:
    field: operator
    pattern: $$OP
```

### Named vs Unnamed Nodes

| Named Nodes                      | Unnamed Nodes      |
|----------------------------------|--------------------|
| `identifier`, `string`, `number` | `+`, `-`, `*`, `/` |
| `function_declaration`           | `(`, `)`, `{`, `}` |
| `call_expression`                | `,`, `;`, `:`      |

Use `--debug-query=cst` to see which nodes are unnamed.

### Examples

```yaml
# Capture binary operator
rule:
  kind: binary_expression
  pattern: $LEFT $$OP $RIGHT

# Match any comparison
pattern: $A $$CMP $B
# Matches: x == y, a != b, n > m
```

---

## $$$VAR — Multiple Nodes

Matches **zero or more** AST nodes. Non-greedy.

```yaml
pattern: console.log($$$ARGS)
# Matches: console.log()
# Matches: console.log("a")
# Matches: console.log("a", "b", "c")
```

### Use Cases

**Variable arguments:**

```yaml
pattern: fn($$$ARGS)
# Matches fn(), fn(a), fn(a, b, c)
```

**Function body:**

```yaml
pattern: function $NAME($$$PARAMS) { $$$ }
# Captures any number of parameters and statements
```

**Array/object contents:**

```yaml
pattern: [$$$ITEMS]
# Matches [], [1], [1, 2, 3]
```

### In Rewrites

```yaml
rule:
  pattern: oldFunc($$$ARGS)
fix: newFunc($$$ARGS)
# Preserves all arguments
```

---

## $_VAR — Non-Capturing

Underscore prefix **disables capture** — each occurrence can match different content.

```yaml
pattern: $_FUNC($_ARG)
# Matches: foo(bar), test(123), a(b)
# Does NOT enforce FUNC or ARG equality
```

### Performance Benefit

Non-capturing skips HashMap bookkeeping, improving match speed.

### Use Cases

**Match any call without caring about details:**

```yaml
pattern: $_($$$)
# Matches any function call
```

**Wildcard in complex patterns:**

```yaml
pattern: $_OBJ.$METHOD($_ARG)
# Matches any method call on any object
```

**Compare with capturing:**

```yaml
# Capturing: same function called twice
pattern: $FUNC($A); $FUNC($B)

# Non-capturing: any two calls
pattern: $_FUNC($_A); $_FUNC($_B)
```

---

## Detection Limitations

Meta-variables must be the **only content** in their AST node.

### ❌ Won't Work

| Pattern          | Problem                 |
|------------------|-------------------------|
| `obj.on$EVENT`   | Mixed with text         |
| `"Hello $WORLD"` | Inside string literal   |
| `a $OP b`        | Operator isn't isolated |
| `$jq`            | Lowercase               |
| `prefix$VAR`     | Mixed content           |

### ✅ Works

| Pattern       | Why                          |
|---------------|------------------------------|
| `obj.$METHOD` | $METHOD is entire identifier |
| `$STRING`     | Entire string node           |
| `$A.$B`       | Each is complete node        |
| `$FUNC($$$)`  | Each is complete node        |

### Workaround: regex

For partial matching, use `regex` instead:

```yaml
rule:
  kind: identifier
  regex: ^on[A-Z]
# Matches: onClick, onChange, onSubmit
```

---

## Meta-Variables in Constraints

Filter captured content:

```yaml
rule:
  pattern: $FUNC($$$ARGS)

constraints:
  FUNC:
    regex: ^(get|fetch|load)
  ARGS:
    has:
      kind: string
```

---

## Meta-Variables in Transforms

Manipulate before use in fix:

```yaml
rule:
  pattern: $OBJ.$METHOD

transform:
  UPPER:
    convert:
      source: $METHOD
      toCase: upperCase

fix: $OBJ.$UPPER
```

---

## Meta-Variables in Fix

Reference captured content in replacements:

```yaml
rule:
  pattern: var $NAME = $VALUE
fix: const $NAME = $VALUE
```

**With multiple captures:**

```yaml
rule:
  pattern: $OBJ && $OBJ.$PROP
fix: $OBJ?.$PROP
```

---

## Quick Reference

| Syntax   | Captures | Matches        | Equality     |
|----------|----------|----------------|--------------|
| `$VAR`   | Yes      | 1 named node   | Enforced     |
| `$$VAR`  | Yes      | 1 unnamed node | Enforced     |
| `$$$VAR` | Yes      | 0+ nodes       | N/A          |
| `$_VAR`  | No       | 1 named node   | Not enforced |
| `$_`     | No       | 1 named node   | Not enforced |

---

## Debugging Tips

1. **Pattern not matching?**
    - Check if meta-variable is entire node
    - Use `--debug-query=pattern` to see interpretation

2. **Wrong capture?**
    - Verify node boundaries with `--debug-query=cst`
    - Check named vs unnamed status

3. **Equality not working?**
    - Ensure same spelling: `$VAR` vs `$Var` are different
    - Check for whitespace differences in captured content
