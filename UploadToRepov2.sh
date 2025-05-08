#!/bin/bash

# Define the branch name variable
BRANCH_NAME="main"  # Change this to the desired branch (e.g., 'dev', 'feature/json-upload')

# Existing script logic (generating JSON files)
# For example:
# generate_json_files.sh (outputs files like dev_storage_accounts.json, tst_storage_accounts.json, etc.)

# Step 1: Ensure the repository is checked out and json directory exists
REPO_DIR=$(pwd)  # Should point to the repository root (e.g., /var/adoagent/_work/1/s/self)
JSON_DIR="$REPO_DIR/json"

# Create the json directory if it doesn't exist
if [ ! -d "$JSON_DIR" ]; then
  echo "Creating json directory at $JSON_DIR"
  mkdir -p "$JSON_DIR"
fi

# Step 2: Move all JSON files matching the pattern to the json folder
echo "Moving JSON files to $JSON_DIR/"
JSON_FILES=$(ls *_storage_accounts.json 2>/dev/null)
if [ -z "$JSON_FILES" ]; then
  echo "Error: No JSON files found matching pattern *_storage_accounts.json"
  exit 1
fi

for file in $JSON_FILES; do
  if ! mv "$file" "$JSON_DIR/"; then
    echo "Error: Failed to move $file to $JSON_DIR/"
    exit 1
  fi
done

# Step 3: Identify existing JSON files in the json folder (excluding the newly moved files)
# Store the list of new files to exclude them from deletion
NEW_FILES=$(ls "$JSON_DIR"/*_storage_accounts.json 2>/dev/null | xargs -n 1 basename)

# Step 4: Configure git for committing
git config --global user.email "azure-devops@yourdomain.com"
git config --global user.name "Azure DevOps Pipeline"

# Step 5: Add and commit the new JSON files
cd "$REPO_DIR"
for file in $JSON_FILES; do
  git add "json/$file"
done
git commit -m "Add new JSON files to json folder"

# Step 6: Push the new JSON files to the repository
if git push origin HEAD:"$BRANCH_NAME"; then
  # Push was successful, delete existing JSON files (excluding the new ones)
  EXISTING_FILES=$(ls "$JSON_DIR"/*_storage_accounts.json 2>/dev/null | grep -v -F "$NEW_FILES")
  if [ -n "$EXISTING_FILES" ]; then
    for old_file in $EXISTING_FILES; do
      if [ -f "$old_file" ]; then
        git rm "$old_file"
      fi
    done
    git commit -m "Remove old JSON files from json folder"
    git push origin HEAD:"$BRANCH_NAME"
  fi
else
  echo "Error: Failed to push new JSON files to branch $BRANCH_NAME. Aborting deletion of existing files."
  exit 1
fi
