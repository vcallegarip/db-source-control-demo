#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

# Allowed file extensions (Modify as needed)
allowed_extensions = {".sql"}  # Example: Only backup SQL and C# files

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# Define backup folder
backup_folder = "db_mods"
os.makedirs(backup_folder, exist_ok=True)  # Ensure the folder exists

# Get script name to prevent self-copying
script_name = os.path.basename(__file__)

for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files
        
    # Check file extension
    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  # Skip files that don’t match allowed extensions

    # Preserve original folder structure in backup
    destination = os.path.join(backup_folder, file)

    # Skip copying the script itself
    if os.path.basename(file) == script_name:
        continue

    # Create necessary subdirectories
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Copy file, overwriting if it already exists
    shutil.copy(file, destination)
    print("Backed up:", file, "->", destination)

print("Pre-commit checks passed.")
sys.exit(0)
