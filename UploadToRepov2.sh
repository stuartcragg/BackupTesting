#!/bin/bash

# Exit on any command failure to ensure pipeline fails
set -e

# Define the branch name variable
BRANCH_NAME="main"  # Change this to the desired branch (e.g., 'dev', 'feature/json-upload')

# Get environments from command-line argument
environments="$1"
if [ -z "$environments" ]; then
  echo "Error: environments argument not provided. Usage: $0 \"dev,tst\" or $0 \"acc,prd\""
  exit 1
fi

# Step 1: Ensure the repository is checked out and azure_vault directory exists
REPO_DIR=$(pwd)  # Confirmed as /var/adoagent/_work/1/s/self
JSON_DIR="$REPO_DIR/azure_vault"  # Path to azure_vault folder

echo "Repository root: $REPO_DIR"
echo "JSON directory: $JSON_DIR"

# Create the azure_vault directory if it doesn't exist
if [ ! -d "$JSON_DIR" ]; then
  echo "Creating azure_vault directory at $JSON_DIR"
  mkdir -p "$JSON_DIR"
fi

# Step 2: Process JSON files for each environment in the comma-separated list
echo "Processing JSON files for environments: $environments"
JSON_FILES=""
IFS=',' read -r -a ENV_ARRAY <<< "$environments"  # Split comma-separated environments into an array
for env in "${ENV_ARRAY[@]}"; do
  FILE_PATTERN="${env}_*.json"
  echo "Checking for files matching $FILE_PATTERN"
  ENV_FILES=$(ls $FILE_PATTERN 2>/dev/null || true)
  if [ -z "$ENV_FILES" ]; then
    echo "Warning: No JSON files found for pattern $FILE_PATTERN"
    continue
  fi
  for file in $ENV_FILES; do
    echo "Moving (overwriting) $file to $JSON_DIR/"
    mv -f "$file" "$JSON_DIR/"
    JSON_FILES="$JSON_FILES azure_vault/$file"
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

# Step 4: Add the JSON files
cd "$REPO_DIR"
for file in $JSON_FILES; do
  echo "Adding $file to git"
  if ! git add "$file"; then
    echo "Error: Failed to add $file to git"
    exit 1
  fi
done

# Step 5: Check for changes before committing
if git status --porcelain | grep -q .; then
  echo "Changes detected, committing and pushing"
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  git commit -m "Add JSON files for environments $environments ($TIMESTAMP)"
  echo "Pushing changes to branch $BRANCH_NAME"
  git push origin HEAD:"$BRANCH_NAME"
else
  echo "No changes to commit for environments $environments"
  exit 0  # Exit successfully if no changes
fi
