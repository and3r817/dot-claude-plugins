#!/usr/bin/env python3
"""Native Timeout Enforcer - Enforces Bash tool timeout parameter"""
import json
import sys

def parse_duration(cmd: str) -> tuple[str, str]:
    """Extract duration and command without regex where possible"""
    # Fast path: check if starts with timeout/gtimeout
    tokens = cmd.strip().split()
    if not tokens or tokens[0] not in ('timeout', 'gtimeout'):
        return '', cmd

    # Find duration (first numeric argument after timeout)
    duration = '5'
    cmd_start_idx = 1

    for i, token in enumerate(tokens[1:], 1):
        if token.startswith('--'):
            continue  # Skip flags
        # Check if token is duration (ends with s/m/h/d or pure digits)
        if token[-1] in 'smhd' and token[:-1].isdigit():
            duration = token
            cmd_start_idx = i + 1
            break
        elif token.isdigit():
            duration = token
            cmd_start_idx = i + 1
            break

    actual_cmd = ' '.join(tokens[cmd_start_idx:])
    return duration, actual_cmd

def to_ms(duration: str) -> str:
    """Convert duration to milliseconds (NO REGEX)"""
    if duration.endswith('s') and duration[:-1].isdigit():
        return str(int(duration[:-1]) * 1000)
    if duration.endswith('m') and duration[:-1].isdigit():
        return str(int(duration[:-1]) * 60000)
    if duration.isdigit():
        return str(int(duration) * 1000)
    return "5000"

def main():
    try:
        data = json.load(sys.stdin)
        cmd = data.get('tool_input', {}).get('command', '')

        if not cmd:
            sys.exit(0)

        cmd_stripped = cmd.strip()

        # Pattern 1: Direct timeout at start (NO REGEX)
        if cmd_stripped.startswith('timeout ') or cmd_stripped.startswith('gtimeout '):
            duration, actual = parse_duration(cmd)
            ms = to_ms(duration)

            sys.stderr.write(f"""⚠️ Direct timeout blocked
Use Bash timeout parameter: Bash(command="{actual}", timeout={ms})
""")
            sys.exit(2)

        # Pattern 2 & 3: timeout in chains/pipes (minimal string ops)
        if ' timeout ' in cmd or ' gtimeout ' in cmd:
            # Quick check before expensive operations
            if any(sep in cmd for sep in ('&&', '||', ';', '|')):
                sys.stderr.write(f"""⚠️ Timeout in command chain blocked
Split into separate Bash calls with timeout parameter
""")
                sys.exit(2)

        sys.exit(0)

    except Exception:
        sys.exit(0)

if __name__ == "__main__":
    main()
