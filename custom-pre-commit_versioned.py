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

# TODO: Add log files into each database folder to track changes then script out PROD

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
build_folder = os.path.join("db_mods", next_build_version)
os.makedirs(build_folder, exist_ok=True)

# Get staged files
staged_files = subprocess.run(
    ["git", "diff", "--name-only", "--cached"],
    capture_output=True, text=True
).stdout.splitlines()

if not staged_files:
    print("No files staged for commit. Skipping pre-commit check.")
    sys.exit(0)

# Dictionary to store committed files per database
db_committed_files = {}

# Preserve folder structure inside DB
for file in staged_files:
    if not os.path.exists(file):
        continue  # Skip deleted files
    
    if not any(file.endswith(ext) for ext in allowed_extensions):
        continue  # Skip files that don’t match allowed extensions

    # Ensure it belongs inside DB folder
    if not file.startswith("DB/"):
        continue

    # Extract database name from the file path (assuming `DB/DatabaseName/...`)
    parts = file.split(os.sep)
    if len(parts) < 2:
        print(f"Skipping file {file} due to incorrect path structure.")
        continue

    db_name = parts[1]  # Extract database name
    db_folder = os.path.join(build_folder, db_name)
    os.makedirs(db_folder, exist_ok=True)  # Ensure DB folder exists

    # Compute destination path inside build folder
    destination = os.path.join(db_folder, os.path.relpath(file, start="DB"))
    
    # Create necessary subdirectories
    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Copy file, overwriting if it already exists
    shutil.copy(file, destination)
    print("Backed up:", file, "->", destination)

    # Store committed files per database
    if db_name not in db_committed_files:
        db_committed_files[db_name] = []
    db_committed_files[db_name].append(file)

# Save committed files per database inside versioned folder
for db_name, files in db_committed_files.items():
    committed_files_path = os.path.join(build_folder, db_name, "committed_files.txt")
    with open(committed_files_path, "w") as f:
        for file in files:
            f.write(file + "\n")
    print(f"Committed files saved for {db_name}: {committed_files_path}")

print("Pre-commit checks passed.")
sys.exit(0)
