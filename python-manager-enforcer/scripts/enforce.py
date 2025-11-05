#!/usr/bin/env python3
"""
Python Package Manager Enforcer Hook
Blocks direct python/python3 commands when a package manager is detected.
"""

import json
import os
import re
import sys
from pathlib import Path


def detect_package_manager(project_dir):
    """Detect package manager from project files."""
    if not project_dir or not os.path.isdir(project_dir):
        return None

    project_path = Path(project_dir)

    # Poetry: poetry.lock or pyproject.toml with [tool.poetry]
    if (project_path / "poetry.lock").exists():
        return "poetry"

    pyproject = project_path / "pyproject.toml"
    if pyproject.exists():
        try:
            content = pyproject.read_text()
            if "[tool.poetry]" in content:
                return "poetry"
            if "[tool.pdm]" in content:
                return "pdm"
            if "[tool.hatch]" in content:
                return "hatch"
        except Exception:
            pass

    # UV: uv.lock or .python-version
    if (project_path / "uv.lock").exists():
        return "uv"

    # Rye: rye.lock or .python-version with rye markers
    if (project_path / "rye.lock").exists():
        return "rye"

    python_version = project_path / ".python-version"
    if python_version.exists():
        try:
            content = python_version.read_text()
            if "rye" in content.lower() or (project_path / ".rye").exists():
                return "rye"
            # Default to uv if .python-version exists without rye markers
            return "uv"
        except Exception:
            pass

    # PDM: pdm.lock
    if (project_path / "pdm.lock").exists():
        return "pdm"

    # Pixi: pixi.lock or pixi.toml
    if (project_path / "pixi.lock").exists() or (project_path / "pixi.toml").exists():
        return "pixi"

    # Conda/Mamba: environment.yml or conda.yml
    if (project_path / "environment.yml").exists() or (project_path / "conda.yml").exists():
        return "conda"

    return None


def get_run_command(manager):
    """Get the run command for a package manager."""
    run_commands = {
        "poetry": "poetry run",
        "uv": "uv run",
        "pdm": "pdm run",
        "hatch": "hatch run",
        "rye": "rye run",
        "pixi": "pixi run",
        "conda": "conda run -n <env_name>",
        "mamba": "mamba run -n <env_name>"
    }
    return run_commands.get(manager, f"{manager} run")


def suggest_replacement(command, manager):
    """Suggest a replacement command using the package manager."""
    pattern = r"^(python3?)(\s.*)$"
    match = re.match(pattern, command)

    if not match:
        return None

    python_cmd = match.group(1)
    rest = match.group(2).strip()

    run_cmd = get_run_command(manager)

    if rest:
        return f"{run_cmd} {python_cmd} {rest}"
    else:
        return f"{run_cmd} {python_cmd}"


def is_bootstrapping_command(command):
    """Check if command is a package manager bootstrapping command."""
    bootstrap_patterns = [
        r"^python3?\s+-m\s+(poetry|uv|pdm|hatch|rye|pixi|pip|conda|mamba)",
    ]

    for pattern in bootstrap_patterns:
        if re.match(pattern, command.strip()):
            return True

    return False


def should_block_command(command):
    """Check if command should be blocked."""
    return bool(re.match(r"^(python3?)(\s)", command.strip()))


def main():
    try:
        stdin_data = sys.stdin.read()
        if not stdin_data:
            sys.exit(0)

        try:
            event_data = json.loads(stdin_data)
        except json.JSONDecodeError:
            sys.exit(0)

        command = event_data.get("tool_input", {}).get("command", "")
        if not command:
            sys.exit(0)

        if is_bootstrapping_command(command):
            sys.exit(0)

        if not should_block_command(command):
            sys.exit(0)

        project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
        manager = detect_package_manager(project_dir)

        if not manager:
            sys.exit(0)

        suggested = suggest_replacement(command, manager)

        sys.stderr.write(f"❌ Direct python blocked. Project uses {manager}: {suggested}")
        sys.exit(2)

    except Exception as e:
        sys.exit(0)


if __name__ == "__main__":
    main()
