#!/usr/bin/env python3
"""Modern CLI Tool Enforcer - Suggests modern CLI alternatives"""
import json
import shutil
import sys


def has_command_word(cmd: str, word: str) -> bool:
    """Check if word appears as a command (not as an argument)"""
    # Split command into segments by shell operators
    for delimiter in ['|', '&&', '||', ';']:
        cmd = cmd.replace(delimiter, '\n')

    # Check first token of each segment
    for segment in cmd.split('\n'):
        tokens = segment.strip().split()
        if tokens and tokens[0] == word:
            return True
    return False


def main():
    try:
        data = json.load(sys.stdin)
        cmd = data.get('tool_input', {}).get('command', '')

        if not cmd:
            sys.exit(0)

        # Check available modern tools & detect legacy usage
        blocks = []
        if shutil.which('rg') and has_command_word(cmd, 'grep'):
            blocks.append(('grep', 'rg'))

        if shutil.which('fd') and has_command_word(cmd, 'find'):
            blocks.append(('find', 'fd'))

        if shutil.which('bat') and has_command_word(cmd, 'cat'):
            blocks.append(('cat', 'bat'))

        if shutil.which('eza') and has_command_word(cmd, 'ls'):
            blocks.append(('ls', 'eza'))

        if blocks:
            suggestions = '\n'.join(f"USE '{new}' instead '{old}'" for old, new in blocks)

            sys.stderr.write(f"❌ Legacy CLI blocked.\n{suggestions}")
            sys.exit(2)

        sys.exit(0)

    except Exception:
        sys.exit(0)


if __name__ == "__main__":
    main()
