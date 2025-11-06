#!/usr/bin/env python3
"""GitHub Write Guard - Blocks gh write operations"""
import json
import sys
from pathlib import Path

WRITE_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE']
WRITE_CMDS = [
    'gh repo create', 'gh repo delete', 'gh repo fork', 'gh repo rename', 'gh repo archive',
    'gh issue create', 'gh issue edit', 'gh issue close', 'gh issue delete',
    'gh issue pin', 'gh issue unpin', 'gh issue transfer',
    'gh pr create', 'gh pr edit', 'gh pr close', 'gh pr merge', 'gh pr reopen',
    'gh pr ready', 'gh pr comment', 'gh pr review',
    'gh release create', 'gh release delete', 'gh release edit', 'gh release upload',
    'gh run cancel', 'gh run rerun',
    'gh workflow enable', 'gh workflow disable', 'gh workflow run',
    'gh gist create', 'gh gist edit', 'gh gist delete',
    'gh project create', 'gh project edit', 'gh project delete',
    'gh project item-add', 'gh project item-edit', 'gh project item-delete',
    'gh project field-create', 'gh project field-delete'
]


def load_settings():
    """Load minimal settings"""
    try:
        settings_file = Path.home() / '.claude' / 'settings.json'
        if settings_file.exists():
            with open(settings_file) as f:
                return json.load(f).get('githubWriteGuard', {})
    except Exception:
        pass
    return {}


def has_method_flag(cmd: str, method: str) -> bool:
    """Check for HTTP method flag (optimized string search) - case insensitive for security"""
    # Fast path: check common patterns without regex (case insensitive)
    cmd_lower = cmd.lower()
    method_lower = method.lower()
    return any(pattern in cmd_lower for pattern in [
        f'-x {method_lower}',
        f'-x{method_lower}',
        f'--method {method_lower}',
        f'--method={method_lower}'
    ])


def has_field_flag(cmd: str) -> bool:
    """Check for field flags that trigger POST (NO REGEX)"""
    tokens = cmd.split()
    for token in tokens:
        if token in ('-f', '-F', '--field', '--raw-field'):
            return True
        if token.startswith('-f') or token.startswith('-F'):
            return True  # -fname or -Fname
    return False


def has_get_method(cmd: str) -> bool:
    """Check if explicitly using GET method"""
    return any(pattern in cmd for pattern in [
        '-X GET',
        '--method GET',
        '--method=GET'
    ])


def main():
    try:
        data = json.load(sys.stdin)
        tool = data.get('tool_name', '')
        cmd = data.get('tool_input', {}).get('command', '')

        # Only check Bash + gh commands (NO REGEX)
        if tool != 'Bash' or not cmd.startswith('gh '):
            sys.exit(0)

        settings = load_settings()
        if not settings.get('enabled', True):
            sys.exit(0)

        # Check gh api write methods
        tokens = cmd.split()
        if len(tokens) >= 2 and tokens[0] == 'gh' and tokens[1] == 'api':
            for method in WRITE_METHODS:
                if has_method_flag(cmd, method):
                    sys.stderr.write(f"❌ GitHub write blocked: gh api {method}")
                    sys.exit(2)

            # Check implicit POST via -f flag
            if has_field_flag(cmd) and not has_get_method(cmd):
                sys.stderr.write("❌ GitHub write blocked: gh api with -f/-F flags (defaults to POST)")
                sys.exit(2)

        # Check write commands
        for write_cmd in WRITE_CMDS:
            if cmd.startswith(write_cmd):
                cmd_name = write_cmd.replace('gh ', '')
                sys.stderr.write(f"❌ GitHub write blocked: gh {cmd_name}")
                sys.exit(2)

        # Command is safe (read-only), allow it
        sys.exit(0)

    except Exception:
        sys.exit(0)


if __name__ == "__main__":
    main()
