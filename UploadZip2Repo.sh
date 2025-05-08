#!/bin/bash

# Existing script logic (generating JSON files and zipping)
# For example:
# generate_json_files.sh
# zip -r resources.zip json_files/

# Step 1: Create a timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)
ZIP_FILE="resources.zip"
TIMESTAMPED_ZIP="resources_${TIMESTAMP}.zip"

# Step 2: Create a copy of the zip file with timestamp
cp "$ZIP_FILE" "$TIMESTAMPED_ZIP"

# Step 3: Ensure the repository is checked out
REPO_DIR=$(pwd)  # Adjust if your repo is in a different directory
JSON_DIR="$REPO_DIR/json"

# Step 4: Identify the existing timestamped zip file (if any)
# Assumes only one file matches the pattern resources_*.zip
EXISTING_ZIP=$(ls "$JSON_DIR"/resources_*.zip 2>/dev/null | head -n 1)

# Step 5: Move the new timestamped zip to the json folder
mv "$TIMESTAMPED_ZIP" "$JSON_DIR/"

# Step 6: Configure git for committing
git config --global user.email "azure-devops@yourdomain.com"
git config --global user.name "Azure DevOps Pipeline"

# Step 7: Add and commit the new timestamped zip
cd "$REPO_DIR"
git add "json/$TIMESTAMPED_ZIP"
git commit -m "Add timestamped zip file: $TIMESTAMPED_ZIP"

# Step 8: Push the new zip to the repository
if git push origin HEAD:main; then
  # Push was successful, delete the existing zip file (if it exists)
  if [ -n "$EXISTING_ZIP" ] && [ -f "$EXISTING_ZIP" ]; then
    # Remove the existing zip from git and the filesystem
    git rm "$EXISTING_ZIP"
    git commit -m "Remove old timestamped zip file: $(basename "$EXISTING_ZIP")"
    git push origin HEAD:main
  fi
else
  echo "Error: Failed to push new zip file. Aborting deletion of existing zip."
  exit 1
fi
