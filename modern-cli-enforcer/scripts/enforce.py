#!/usr/bin/env python3
"""Modern CLI Tool Enforcer - Suggests modern CLI alternatives"""
import json
import sys
import shutil

def has_command_word(cmd: str, word: str) -> bool:
    """Check if command contains word as standalone token (fast alternative to \b regex)"""
    # Split on common shell delimiters
    tokens = cmd.replace('|', ' ').replace('&&', ' ').replace('||', ' ').replace(';', ' ').split()
    return word in tokens

def main():
    try:
        data = json.load(sys.stdin)
        cmd = data.get('tool_input', {}).get('command', '')

        if not cmd:
            sys.exit(0)

        # Check available modern tools & detect legacy usage (NO REGEX)
        blocks = []
        if shutil.which('rg') and has_command_word(cmd, 'grep'):
            blocks.append(('grep', 'ripgrep (rg)', "grep 'pattern' → rg 'pattern'"))

        if shutil.which('fd') and has_command_word(cmd, 'find'):
            blocks.append(('find', 'fd', "find . -name '*.txt' → fd '*.txt'"))

        if shutil.which('bat') and has_command_word(cmd, 'cat'):
            blocks.append(('cat', 'bat', 'cat file.py → bat file.py'))

        if shutil.which('eza') and has_command_word(cmd, 'ls'):
            blocks.append(('ls', 'eza', 'ls -la → eza -la'))

        if blocks:
            tools = '\n'.join(f"  • Use {new} instead of {old}" for old, new, _ in blocks)
            examples = '\n'.join(f"  {ex}" for _, _, ex in blocks)

            sys.stderr.write(f"""⚠️  Legacy CLI tool(s) detected. Modern alternatives are available:

{tools}

**Why modern tools?**
  - Faster performance (parallel processing)
  - Better defaults (smart ignore patterns)
  - Improved UX (colors, formatting)

**Example replacements:**
{examples}

This command will be **blocked**. Please use modern alternatives.
""")
            sys.exit(2)

        sys.exit(0)

    except Exception:
        sys.exit(0)

if __name__ == "__main__":
    main()
