#!/usr/bin/env python3
"""Patch ModuleUpdate.py to auto-confirm in non-interactive Docker environments."""

with open('/app/ModuleUpdate.py', 'r') as f:
    lines = f.readlines()

# Find and replace the confirm function
new_lines = []
in_confirm = False
skip_until_next_def = False

for i, line in enumerate(lines):
    if 'def confirm(' in line and not in_confirm:
        # Found the confirm function, replace it
        new_lines.append('def confirm(msg):\n')
        new_lines.append('    """Auto-confirm in Docker - non-interactive mode"""\n')
        new_lines.append('    print(f"Auto-confirming: {msg}")\n')
        new_lines.append('    return True\n')
        in_confirm = True
        skip_until_next_def = True
    elif skip_until_next_def:
        # Skip old function body until we hit the next function or non-indented line
        if line.strip() and not line.startswith(' ') and not line.startswith('\t'):
            # End of function, back to normal
            skip_until_next_def = False
            new_lines.append(line)
        elif line.strip().startswith('def ') and in_confirm:
            # Hit next function definition
            skip_until_next_def = False
            in_confirm = False
            new_lines.append(line)
    else:
        new_lines.append(line)

with open('/app/ModuleUpdate.py', 'w') as f:
    f.writelines(new_lines)

print("ModuleUpdate.py patched successfully for Docker")
