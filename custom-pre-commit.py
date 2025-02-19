#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

# Allowed file extensions (Modify as needed)
allowed_extensions = {".sql"}  

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# Define source and backup folder
source_folder = "DB" # DB or whatever the powershell uses to script out DBs
backup_folder = "db_mods"
os.makedirs(backup_folder, exist_ok=True)  # Ensure the folder exists

# Get script name to prevent self-copying
script_name = os.path.basename(__file__)

for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files
    
    # Ensure the file is inside the DB folder
    if not file.startswith(source_folder + "/"):
        continue  # Ignore files outside of DB

    # Preserve "DB/" structure inside db_mods
    destination = os.path.join(backup_folder, file)

    # Skip copying the script itself
    if os.path.basename(file) == script_name:
        continue

    # Create necessary subdirectories in db_mods
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Copy file, overwriting if it already exists
    shutil.copy(file, destination)
    print("Backed up:", file, "->", destination)

print("Pre-commit checks passed.")
sys.exit(0)


# 1) Query SQL Server to get the latest build number from a table (e.g., BuildHistory).
# 2) Determine the next build number by incrementing the latest retrieved version.
# 3) Create a new folder in db_mods/, using the determined build number (e.g., db_mods/0.0.2/DB/).
# 4) Allow manual build versions (e.g., if the user manually sets 0.0.5, don’t enforce sequence checks).
# 5) Copy all staged files under DB/, preserving folder structure.