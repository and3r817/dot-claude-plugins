# YAML Configuration

Complete reference for ast-grep YAML rule configuration beyond basic rules.

## Constraints

Filter meta-variables with additional rules **after** main matching.

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

### Structure

Each key is a meta-variable name (without `$`), value is a rule object:

```yaml
constraints:
  VAR_NAME:
  # Any rule: pattern, kind, regex, has, inside, all, any, not, etc.
```

### Examples

```yaml
# Only match lowercase identifiers
constraints:
  NAME:
    regex: ^[a-z]

# Ensure argument is a string literal
constraints:
  ARG:
    kind: string

# Exclude specific values
constraints:
  VALUE:
    not:
      regex: ^(null|undefined)$

# Complex constraint
constraints:
  FUNC:
    all:
      - kind: identifier
      - regex: ^use[A-Z]
```

---

## Transform

Manipulate meta-variables before use in `fix`.

```yaml
rule:
  pattern: $OBJ.$METHOD($$$ARGS)

transform:
  UPPER_METHOD:
    convert:
      source: $METHOD
      toCase: upperCase

fix: $OBJ.$UPPER_METHOD($$$ARGS)
```

### Operations

#### replace

Regex-based string replacement:

```yaml
transform:
  CLEANED:
    replace:
      source: $VAR
      pattern: "old"
      replacement: "new"
```

#### convert

Case conversion:

```yaml
transform:
  RESULT:
    convert:
      source: $VAR
      toCase: upperCase    # lowerCase, upperCase, camelCase, pascalCase, snakeCase, kebabCase
```

#### substring

Extract portion of text:

```yaml
transform:
  PREFIX:
    substring:
      source: $VAR
      startChar: 0
      endChar: 3
```

### Multiple Transforms

```yaml
transform:
  CLEAN_NAME:
    replace:
      source: $NAME
      pattern: "^_+"
      replacement: ""
  UPPER_NAME:
    convert:
      source: $CLEAN_NAME
      toCase: upperCase
```

---

## Fix Configuration

### Simple Fix

```yaml
fix: newPattern($CAPTURED)
```

### Delete Match

Empty string deletes the matched code:

```yaml
fix: ""
```

### FixConfig Object

For range expansion:

```yaml
fix:
  template: $REPLACEMENT
  expandStart:
    kind: decorator
  expandEnd:
    pattern: ;
```

| Field         | Description                |
|---------------|----------------------------|
| `template`    | Replacement string         |
| `expandStart` | Rule to expand match start |
| `expandEnd`   | Rule to expand match end   |

### Example: Remove with Decorator

```yaml
rule:
  pattern: @deprecated

fix:
  template: ""
  expandEnd:
    kind: function_declaration
# Removes @deprecated AND the function it decorates
```

---

## Rewriters

Custom transformation rules for complex rewrites:

```yaml
rewriters:
  - id: simplify-ternary
    rule:
      pattern:
        $COND ? true: false
    fix: Boolean($COND)

  - id: remove-double-negation
    rule:
      pattern: !!$EXPR
    fix: Boolean($EXPR)

rule:
  any:
    - matches: simplify-ternary
    - matches: remove-double-negation
```

### Structure

Each rewriter has:

| Field         | Description          |
|---------------|----------------------|
| `id`          | Unique identifier    |
| `rule`        | Matching rule        |
| `fix`         | Replacement pattern  |
| `constraints` | Optional constraints |
| `transform`   | Optional transforms  |

---

## Linting Fields

### severity

```yaml
severity: error    # hint | info | warning | error | off
```

| Level     | Use Case                       |
|-----------|--------------------------------|
| `hint`    | Suggestions, style preferences |
| `info`    | Informational, non-blocking    |
| `warning` | Should fix, but not critical   |
| `error`   | Must fix, blocks CI            |
| `off`     | Disable rule                   |

### message

Single-line explanation. **Supports meta-variables:**

```yaml
message: "Avoid using $FUNC directly, use wrapper instead"
```

### note

Extended markdown explanation. **No meta-variables:**

```yaml
note: |
  ## Why This Matters

  Using this pattern can cause **performance issues** because:
  - Reason 1
  - Reason 2

  ### Recommended Alternative

  ```javascript
  // Use this instead
  wrapper(value)
  ```

See [documentation](https://example.com) for details.

```

### labels

Custom highlighting for meta-variables:

```yaml
labels:
  FUNC:
    style: primary
    message: "This function is deprecated"
  ARG:
    style: secondary
    message: "Consider validating this input"
```

| Style       | Appearance                                    |
|-------------|-----------------------------------------------|
| `primary`   | Main highlight (usually red/error)            |
| `secondary` | Supporting highlight (usually yellow/warning) |

### url

Documentation link (shown in editors):

```yaml
url: "https://example.com/rules/no-console"
```

---

## File Filtering

### files

Include **only** matching files:

```yaml
files:
  - "src/**/*.ts"
  - "lib/**/*.js"
  - "!**/*.d.ts"        # Negation pattern
```

### ignores

Exclude matching files (checked **before** `files`):

```yaml
ignores:
  - "**/*.test.ts"
  - "**/*.spec.js"
  - "**/node_modules/**"
  - "**/dist/**"
  - "**/__mocks__/**"
```

### Evaluation Order

1. Check `ignores` — if matches, skip file
2. Check `files` — if specified and doesn't match, skip file
3. Apply rule

---

## Metadata

Custom data for external tools:

```yaml
metadata:
  category: "security"
  fixable: true
  deprecated: false
  cwe: "CWE-79"
  owasp: "A7:2017"
```

Access via `--include-metadata` flag:

```bash
ast-grep scan --json --include-metadata .
```

---

## Utils (Utility Rules)

Define reusable rules within a file:

```yaml
utils:
  is-console:
    any:
      - pattern: console.log($$$)
      - pattern: console.warn($$$)
      - pattern: console.error($$$)

  is-loop:
    any:
      - kind: for_statement
      - kind: while_statement

rule:
  matches: is-console
  inside:
    matches: is-loop
    stopBy: end
```

### Global Utils

Share across files via `sgconfig.yml`:

```yaml
# sgconfig.yml
utilDirs:
  - ./shared-utils
```

---

## Multiple Rules Per File

Separate rules with `---`:

```yaml
id: no-console-log
language: javascript
severity: warning
rule:
  pattern: console.log($$$)
---
id: no-console-warn
language: javascript
severity: info
rule:
  pattern: console.warn($$$)
---
id: no-console-error
language: javascript
severity: error
rule:
  pattern: console.error($$$)
```

---

## Complete Example

```yaml
id: no-await-in-loop
language: typescript
severity: warning
message: "Avoid await inside $LOOP - use Promise.all instead"
note: |
  Sequential awaits in loops cause performance issues.

  ### Bad
  ```typescript
  for (const item of items) {
    await process(item);  // Sequential, slow
  }
  ```

### Good

  ```typescript
  await Promise.all(items.map(item => process(item)));
  ```

url: "https://eslint.org/docs/rules/no-await-in-loop"

utils:
is-loop:
any:
- kind: for_statement
- kind: for_in_statement
- kind: for_of_statement
- kind: while_statement

rule:
pattern: await $PROMISE
inside:
matches: is-loop
stopBy: end

constraints:
PROMISE:
not:
pattern: Promise.all($$$)

labels:
PROMISE:
style: primary
message: "This await runs sequentially"

files:

- "src/**/*.ts"
- "src/**/*.tsx"

ignores:

- "**/*.test.ts"
- "**/*.spec.ts"

metadata:
category: performance
fixable: false
effort: medium

```

---

## sgconfig.yml Reference

Project configuration file:

```yaml
# Rule directories
ruleDirs:
  - ./rules
  - ./custom-rules

# Shared utility rules
utilDirs:
  - ./shared-utils

# Test configuration
testConfigs:
  - testDir: ./rule-tests
    snapshotDir: ./rule-tests/__snapshots__

# Language-specific settings
languageGlobs:
  typescript:
    - "*.ts"
    - "*.tsx"
    - "*.mts"
```
