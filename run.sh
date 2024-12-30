clear and update ini


#!/bin/bash

# Usage: ./replace_ini_content.sh <repository_url> <ini_file_path> [branch]

# Ensure the script has at least two arguments
if [ "$#" -lt 2 ]; then
  echo "Error: Insufficient arguments provided."
  echo "Usage: $0 <repository_url> <ini_file_path> [branch]"
  exit 1
fi

# Assign input arguments to variables
REPO_URL=$1
INI_FILE_PATH=$2
BRANCH=${3:-main} # Default branch is 'main' if not specified

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

# Clone the repository
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

# Prompt user for an action
echo ""
echo "What would you like to do?"
echo "1. Clear the existing content and add new content to the .ini file"
echo "2. Exit"
read -p "Enter your choice (1 or 2): " CHOICE

if [ "$CHOICE" -eq 1 ]; then
  # Prompt user for the new content of the .ini file
  echo "Enter the new content for the .ini file. To finish, press Ctrl+D."
  cat > "$TEMP_DIR/$INI_FILE_PATH"

  # Display the new content
  echo "New content has been written to $INI_FILE_PATH:"
  cat "$TEMP_DIR/$INI_FILE_PATH"

  # Commit the changes back to the repository
  cd "$TEMP_DIR"
  git config user.name "Automated Script"
  git config user.email "script@example.com"
  git add "$INI_FILE_PATH"
  git commit -m "Replaced content of $INI_FILE_PATH" > /dev/null 2>&1
  git push origin "$BRANCH" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "Error: Failed to push the updates to the repository."
  else
    echo "Updates have been pushed to the repository."
  fi
elif [ "$CHOICE" -eq 2 ]; then
  echo "Exiting without making changes."
else
  echo "Invalid choice. Exiting."
fi

# Clean up
rm -rf "$TEMP_DIR"
echo "Temporary directory removed."