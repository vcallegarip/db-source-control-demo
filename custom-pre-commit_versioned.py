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
ENABLE_PROD_COMPARISON = sys.argv[6].lower() == "true"

# Allowed file extensions
allowed_extensions = {".sql", ".SQL"}

# Function to get the latest build version from SQL Server
def get_latest_build_version():
    try:
        if DB_USER and DB_PASSWORD:
            conn = pyodbc.connect(
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={DB_SERVER};"
                f"DATABASE={DB_NAME};"
                f"UID={DB_USER};"
                f"PWD={DB_PASSWORD};"
            )
        else:
            conn = (
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={DB_SERVER};"
                f"DATABASE={DB_NAME};"
                f"Trusted_Connection=yes;"
            )
        cursor = conn.cursor()
        cursor.execute(f"SELECT TOP 1 BuildVersion FROM {TABLE_NAME} ORDER BY BuildVersion DESC;")
        row = cursor.fetchone()
        conn.close()

        return row[0] if row else "0.0.0"
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)

# Function to increment the build version
def get_next_build_version(latest_version):
    match = re.match(r"(\d+)\.(\d+)\.(\d+)", latest_version)
    if match:
        major, minor, patch = map(int, match.groups())
        return f"{major}.{minor}.{patch + 1}"
    return "0.0.1"

# Get latest and next build versions
latest_build_version = get_latest_build_version()
next_build_version = get_next_build_version(latest_build_version)

# Create build folder for this version
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

# Track committed files (without brackets) with their object type
committed_files = []

# Preserve folder structure inside DB
for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files

    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  # Skip files that don’t match allowed extensions

    # Ensure the file is inside the DB folder
    if not file.startswith("DB/"):
        continue

    # Extract relative path inside the DB/{DB_NAME} structure
    relative_path = os.path.relpath(file, os.path.join("DB", DB_NAME))

    # Compute destination path inside the correct database folder in db_mods
    destination = os.path.join(build_folder, relative_path)

    # Ensure subdirectories exist
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Copy file, overwriting if it already exists
    shutil.copy(file, destination)
    print("Backed up:", file, "->", destination)

    # Extract object name without brackets
    object_name = os.path.splitext(os.path.basename(file))[0]  # Remove .sql extension
    object_name = object_name.replace("[", "").replace("]", "")  # Remove brackets

    # Extract object type from folder structure
    path_parts = relative_path.split(os.sep)
    if len(path_parts) > 1:
        object_type = path_parts[0]  # The folder name, e.g., "StoredProcedures"
    else:
        object_type = "Unknown"  # If somehow misplaced

    # Append to committed files list
    committed_files.append(f"{object_name} ({object_type})")

# Save committed files to a log file
if committed_files:
    with open(committed_files_log, "a", encoding="utf-8") as log_file:  # Append mode
        for file in committed_files:
            log_file.write(file + os.linesep)  # Ensures platform-independent newline
            
    print(f"Committed files logged in: {committed_files_log}")

print("Pre-commit checks passed.")
sys.exit(0)
