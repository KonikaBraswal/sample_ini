#!/bin/bash

# Usage: ./manage_ini_with_enc.sh <repo_url> <ini_file_path> [branch]

# Ensure the script has at least two arguments
if [ "$#" -lt 2 ]; then
  echo "Error: Insufficient arguments provided."
  echo "Usage: $0 <repo_url> <ini_file_path> [branch]"
  exit 1
fi

# Assign input arguments to variables
REPO_URL=$1
INI_FILE_PATH=$2
BRANCH=${3:-main} # Default branch is 'main' if not specified

# Hardcoded repository URLs
BACKUP_REPO_URL="https://github.com/KonikaBraswal/sample_ini.git"  # Repository where backup.txt is located
BACKUP_PATH="backup.txt"  # Hardcoded backup file path in the backup repo

# Ensure Git is installed
if ! command -v git &> /dev/null; then
  echo "Error: Git is not installed. Please install Git and try again."
  exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
if [ $? -ne 0 ]; then
  echo "Error: Failed to create a temporary directory."
  exit 1
fi
echo "Cloning repository to temporary directory: $TEMP_DIR"

# Clone the repository containing the .ini file
git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Failed to clone repository: $REPO_URL (Branch: $BRANCH)"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Check if the .ini file exists
if [ ! -f "$TEMP_DIR/$INI_FILE_PATH" ]; then
  echo "Error: File not found in repository: $INI_FILE_PATH"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Display the contents of the .ini file
echo "Contents of the .ini file ($INI_FILE_PATH):"
cat "$TEMP_DIR/$INI_FILE_PATH"

# Backup the updated .ini file into backup.txt in a different repository
DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
echo "Backup of $INI_FILE_PATH as of $DATE_TIME" >> "$TEMP_DIR/$BACKUP_PATH"
cat "$TEMP_DIR/$INI_FILE_PATH" >> "$TEMP_DIR/$BACKUP_PATH"
echo "" >> "$TEMP_DIR/$BACKUP_PATH"  # Add a newline for separation

# Clone the backup repository
BACKUP_DIR=$(mktemp -d)
git clone --depth 1 "$BACKUP_REPO_URL" "$BACKUP_DIR" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Failed to clone backup repository: $BACKUP_REPO_URL"
  rm -rf "$TEMP_DIR" "$BACKUP_DIR"
  exit 1
fi

# Copy the backup to the backup repository
cp "$TEMP_DIR/$BACKUP_PATH" "$BACKUP_DIR/$BACKUP_PATH"

# Commit the changes back to the backup repository
cd "$BACKUP_DIR"
git config user.name "Automated Script"
git config user.email "script@example.com"
git add "$BACKUP_PATH"
git commit -m "Backup of $INI_FILE_PATH as of $DATE_TIME" > /dev/null 2>&1
git push origin "$BRANCH" > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Error: Failed to push the backup to the backup repository."
else
  echo "Backup has been pushed to the backup repository."
fi

# # Clean up the backup repository
rm -rf "$BACKUP_DIR"