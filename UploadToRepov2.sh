#!/bin/bash

# Define the branch name variable
BRANCH_NAME="main"  # Change this to the desired branch (e.g., 'dev', 'feature/json-upload')

# Define the environments variable (e.g., "dev,tst" or "acc,prd")
# This should be set before running the script, e.g., via pipeline variable or environment
: ${environments:?"Error: environments variable not set. Set to 'dev,tst' or 'acc,prd'."}

# Step 1: Ensure the repository is checked out and json directory exists
REPO_DIR=$(pwd)  # Should point to the repository root (e.g., /var/adoagent/_work/1/s/self)
JSON_DIR="$REPO_DIR/json"

# Create the json directory if it doesn't exist
if [ ! -d "$JSON_DIR" ]; then
  echo "Creating json directory at $JSON_DIR"
  mkdir -p "$JSON_DIR"
fi

# Step 2: Process JSON files for each environment in the comma-separated list
echo "Processing JSON files for environments: $environments"
JSON_FILES=""
IFS=',' read -r -a ENV_ARRAY <<< "$environments"  # Split comma-separated environments into an array
for env in "${ENV_ARRAY[@]}"; do
  FILE_PATTERN="${env}_*.json"
  ENV_FILES=$(ls $FILE_PATTERN 2>/dev/null)
  if [ -z "$ENV_FILES" ]; then
    echo "Warning: No JSON files found for pattern $FILE_PATTERN"
    continue
  fi
  for file in $ENV_FILES; do
    echo "Moving (overwriting) $file to $JSON_DIR/"
    if ! mv -f "$file" "$JSON_DIR/"; then
      echo "Error: Failed to move $file to $JSON_DIR/"
      exit 1
    fi
    JSON_FILES="$JSON_FILES json/$file"
  done
done

# Check if any files were found and moved
if [ -z "$JSON_FILES" ]; then
  echo "Error: No JSON files found for any environment in: $environments"
  exit 1
fi

# Step 3: Configure git for committing
git config --global user.email "azure-devops@yourdomain.com"
git config --global user.name "Azure DevOps Pipeline"

# Step 4: Add and commit the JSON files
cd "$REPO_DIR"
for file in $JSON_FILES; do
  git add "$file"
done
TIMESTAMP=$(date +%Y%m%d%H%M%S)
git commit -m "Add JSON files for environments $environments ($TIMESTAMP)"

# Step 5: Push the JSON files to the repository
if ! git push origin HEAD:"$BRANCH_NAME"; then
  echo "Error: Failed to push JSON files to branch $BRANCH_NAME."
  exit 1
fi
