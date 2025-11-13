# Hook Test Edge Cases Design

**Date**: 2025-01-05
**Decision**: Extend existing test files with comprehensive edge case coverage

## Summary

Adding 52 new tests across 4 hook plugins to improve robustness and catch edge cases.

## Test Additions by Plugin

### Modern CLI Enforcer (+10 tests)

- Multiple legacy tools in single command
- Complex flag combinations
- Tool names in strings/paths (false positive prevention)
- Special characters and Unicode

### GitHub Write Guard (+11 tests)

- HTTP method case sensitivity (security critical)
- Complex command arguments
- Chained write operations
- Method flag variations

### Native Timeout Enforcer (+12 tests)

- Extended duration formats (hours, days)
- Additional timeout flags (--foreground, --kill-after)
- Signal specifications
- Subshell nesting
- Whitespace variations

### Python Manager Enforcer (+19 tests)

- Multiple manager conflict detection (poetry + uv)
- pyproject.toml with multiple [tool.*] sections
- Python variant commands (python2, python3.11, absolute paths)
- Complex arguments (-c inline code, multiple flags)
- Manager-specific detection (pixi.toml, conda.yml)
- .python-version edge cases (rye vs uv detection)
- Bootstrapping with flags

## Implementation Approach

**Pattern**: [Project Convention]

- Extend existing test files (not create new ones)
- Group by category with `print_section` headers
- Use same test framework API (`run_test`)

## Risk Mitigation

1. Temp directory cleanup: Add `trap cleanup EXIT` to Python Manager tests
2. Test execution time: Expected +5-10 seconds (acceptable)
3. JSON escaping: Validated all test JSON structures

## Priority

**Phase 1 (HIGH)**: Security & correctness

- GitHub Write Guard case sensitivity
- Python Manager conflict detection
- Modern CLI multiple tools

**Phase 2 (MEDIUM)**: Robustness

- Native Timeout extended formats
- Complex arguments

**Phase 3 (LOW)**: Polish

- Unicode, whitespace variations
