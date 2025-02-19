#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# Define backup folder for staged files
backup_folder = ".backup_staged_files"
os.makedirs(backup_folder, exist_ok=True)

# File extensions to check (ignore .py to prevent self-blocking)
allowed_extensions = {".cs", ".js", ".html", ".css", ".json", ".md", "py"}

for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files

    # Skip non-source code files
    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  

    with open(file, "r", errors="ignore") as f:
        content = f.read()
        if "TODO" in content:
            print(f"ERROR: 'TODO' found in {file}. Commit aborted!")
            sys.exit(1)

# If all checks pass, copy staged files to backup folder
for file in staged_files:
    if os.path.exists(file):  
        destination = os.path.join(backup_folder, os.path.basename(file))
        shutil.copy(file, destination)
        print(f"Backed up: {file} → {destination}")

print("Pre-commit checks passed.")
sys.exit(0)
