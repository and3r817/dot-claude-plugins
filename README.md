# Claude Code Plugins

A small collection of plugins I use with Claude Code.

## Install Marketplace

```bash
/plugin marketplace add and3r817/dot-claude-plugins
```

## Plugins

- [github-cli](./github-cli/README.md) – GitHub CLI (gh) companion: security guard blocking write operations + comprehensive usage skill for automation, API access, and workflows.

- [modern-cli-enforcer](./modern-cli-enforcer/README.md) – Enforces modern CLI tools (rg, fd, bat, eza) over legacy commands (grep, find, cat, ls).

- [native-timeout-enforcer](./native-timeout-enforcer/README.md) – Prevents use of timeout/gtimeout in Bash; use the Bash tool's native timeout parameter instead.

- [python-manager-enforcer](./python-manager-enforcer/README.md) – Enforces package manager usage by blocking direct python/python3 when a manager is detected and suggesting the correct alternative.

- [codex-advisor](./codex-advisor/README.md) – Advisory consultation skill for architectural reviews, design decisions,
  code analysis, and technology evaluation. Codex provides recommendations without making code changes.

- [android-analysis](./android-analysis/README.md) – Android APK/AAR/JAR decompilation and inspection toolkit for
  analyzing compiled binaries and unpacking libraries.

- [ast-grep](./ast-grep/README.md) – Structural code search using AST patterns. Translates natural language queries into
  ast-grep rules for precise code matching beyond text search.

- [android-kotlin-compose](./android-kotlin-compose/README.md) – Android development guidance with Kotlin and Jetpack
  Compose. MVVM architecture, state management, Navigation, Room, Hilt, and Material3 patterns.

- [android-kotlin-coroutines](./android-kotlin-coroutines/README.md) – Android development guidance with Kotlin
  Coroutines and Flow. Structured concurrency, StateFlow/SharedFlow patterns, testing with Turbine, and library
  integrations.

## Manage

```bash
# List installed
/plugin list

# Uninstall
/plugin uninstall <plugin>
```
