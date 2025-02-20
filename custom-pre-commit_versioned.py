#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil
import pyodbc
import re

# Database Connection Settings
DB_SERVER = sys.argv[1]
DB_NAME = sys.argv[2]
DB_USER = sys.argv[3]
DB_PASSWORD = sys.argv[4]
TABLE_NAME = sys.argv[5]
ENABLE_PROD_COMPARISON = sys.argv[6].lower() == "true"  # Convert to Boolean

# Allowed file extensions
allowed_extensions = {".sql", ".SQL"}

# Function to get the latest build version from SQL Server
def get_latest_build_version():
    try:
        conn = pyodbc.connect(
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_NAME};"
            f"Trusted_Connection=yes;"
        )
        cursor = conn.cursor()
        cursor.execute(f"SELECT TOP 1 BuildVersion FROM {TABLE_NAME} ORDER BY BuildVersion DESC;")
        row = cursor.fetchone()
        conn.close()

        if row:
            return row[0]  # Return the latest version number as a string
        else:
            return "0.0.0"  # Default if no builds exist
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)

# Function to increment the build version
def get_next_build_version(latest_version):
    match = re.match(r"(\d+)\.(\d+)\.(\d+)", latest_version)
    if match:
        major, minor, patch = map(int, match.groups())
        return f"{major}.{minor}.{patch + 1}"  # Increment the patch number
    return "0.0.1"

# Get the latest build version from the database
latest_build_version = get_latest_build_version()
next_build_version = get_next_build_version(latest_build_version)

# Allow manually created versions (don't enforce sequence)
build_folder = os.path.join("db_mods", next_build_version, DB_NAME)
os.makedirs(build_folder, exist_ok=True)

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# File to log committed files per database
committed_files_log = os.path.join(build_folder, "committed_files.txt")

# Preserve folder structure inside DB
committed_files = []
for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files
    
    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  # Skip files that don’t match allowed extensions

    # Ensure it belongs inside DB folder
    if not file.startswith("DB/"):
        continue

    # Extract the object type from the path structure
    relative_path = os.path.relpath(file, "DB")  
    path_parts = relative_path.split(os.sep)

    # Determine object type from folder name
    object_type = path_parts[0] if len(path_parts) > 1 else "Unknown"

    # Compute destination path inside the correct database folder
    destination = os.path.join(build_folder, relative_path)

    # Ensure subdirectories exist
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Copy file, overwriting if it already exists
    shutil.copy(file, destination)
    print("Backed up:", file, "->", destination)
    
    # Extract object name (keeping brackets in db_mods)
    object_name = os.path.basename(file).replace(".SQL", "").replace(".sql", "")

    # Remove brackets **only** for committed_files.txt
    object_name_clean = re.sub(r"[\[\]]", "", object_name)

    # Append to committed files list with its detected type
    committed_files.append(f"{object_name_clean} ({object_type})")

# Save committed files to a log file
if committed_files:
    with open(committed_files_log, "w") as log_file:
        log_file.write("\n".join(committed_files))
    print(f"Committed files logged in: {committed_files_log}")

print("Pre-commit checks passed.")
sys.exit(0)
