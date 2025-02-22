#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil
import pyodbc
import re
import datetime

timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Database Connection Settings
DB_SERVER = sys.argv[1]
DB_USER = sys.argv[2]
DB_PASSWORD = sys.argv[3]
DB_HISTORY_TABLE = sys.argv[4]
ENABLE_PROD_SNAPSHOT = sys.argv[5].lower() == "true"

# Allowed file extensions
allowed_extensions = {".sql", ".SQL"}

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# Extract database names from staged files
db_names = set()
for file in staged_files:
    parts = file.split(os.sep)
    if len(parts) > 1:
        db_names.add(parts[1])  # Extract DB name (folder after "DB/")

print(db_names)

# Ensure a database name was detected
if not db_names:
    print("Error: No database name detected in staged files. Ensure files follow the structure 'DB/DatabaseName/...'.")
    sys.exit(1)

# Ensure only one database is detected
if len(db_names) > 1:
    print(f"Error: Multiple databases detected in staged files: {db_names}")
    sys.exit(1)

DB_NAME = next(iter(db_names))  # Get the single detected database
print(f"Detected Database Name: {DB_NAME}")

# Function to get the latest build version from SQL Server
def get_latest_build_version():
    try:
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_NAME};"
            f"UID={DB_USER};PWD={DB_PASSWORD};"
            if DB_USER and DB_PASSWORD else
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_NAME};"
            f"Trusted_Connection=yes;"
        )
        
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute(f"SELECT TOP 1 BuildVersion FROM {DB_HISTORY_TABLE} ORDER BY BuildVersion DESC;")
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

# Define main directories
base_mods_folder = "db_mods"
build_folder = os.path.join(base_mods_folder, next_build_version, DB_NAME)
committed_changes_folder = os.path.join(build_folder, ".committed_changes")
prod_snapshot_folder = os.path.join(build_folder, ".prod_snapshot")

# Ensure main folders exist
os.makedirs(committed_changes_folder, exist_ok=True)
os.makedirs(prod_snapshot_folder, exist_ok=True)

# File to log committed files per database
committed_files_log = os.path.join(build_folder, "committed_files.txt")

# Track committed files (without brackets) with their object type
committed_files = []

# Process each staged file
for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files

    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  # Skip files that don’t match allowed extensions

    # Ensure the file is inside the DB/{DB_NAME} folder
    if not file.startswith(f"DB/{DB_NAME}/"):
        continue

    # Extract relative path inside DB/{DB_NAME} structure
    relative_path = os.path.relpath(file, f"DB/{DB_NAME}")

    # Compute destination path inside committed_changes folder
    destination = os.path.join(committed_changes_folder, relative_path)

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
    object_type = path_parts[0] if len(path_parts) > 1 else "Unknown"

    # Append to committed files list with timestamp
    committed_files.append(f"[{timestamp}] {object_name} ({object_type})")

# Save committed files to a log file
if committed_files:
    with open(committed_files_log, "a", encoding="utf-8") as log_file:  # Append mode
        for file in committed_files:
            log_file.write(file + "\n")  # Ensure proper line breaks

    print(f"Committed files logged in: {committed_files_log}")

print("Pre-commit checks passed.")
sys.exit(0)
