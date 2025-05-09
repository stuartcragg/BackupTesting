#!/bin/bash

# Define the branch name variable
BRANCH_NAME="main"  # Change this to the desired branch (e.g., 'dev', 'feature/json-upload')

# Step 1: Validate and set environment group
ENV_GROUP="${1:-}"  # Get the first argument (e.g., 'dev-tst' or 'acc-prd')
if [ -z "$ENV_GROUP" ]; then
  echo "Error: Environment group not specified. Use 'dev-tst' or 'acc-prd'."
  exit 1
fi

# Map environment group to specific environments
case "$ENV_GROUP" in
  "dev-tst")
    ENVIRONMENTS="dev tst"
    FILE_PATTERN="{dev,tst}_*.json"
    ;;
  "acc-prd")
    ENVIRONMENTS="acc prd"
    FILE_PATTERN="{acc,prd}_*.json"
    ;;
  *)
    echo "Error: Invalid environment group '$ENV_GROUP'. Use 'dev-tst' or 'acc-prd'."
    exit 1
    ;;
esac

# Step 2: Ensure the repository is checked out and json directory exists
REPO_DIR=$(pwd)  # Should point to the repository root (e.g., /var/adoagent/_work/1/s/self)
JSON_DIR="$REPO_DIR/json"

# Create the json directory if it doesn't exist
if [ ! -d "$JSON_DIR" ]; then
  echo "Creating json directory at $JSON_DIR"
  mkdir -p "$JSON_DIR"
fi

# Step 3: Move JSON files matching the pattern to the json folder, overwriting existing files
echo "Processing JSON files for environments: $ENVIRONMENTS"
JSON_FILES=$(ls $FILE_PATTERN 2>/dev/null)
if [ -z "$JSON_FILES" ]; then
  echo "Error: No JSON files found matching pattern $FILE_PATTERN"
  exit 1
fi

for file in $JSON_FILES; do
  echo "Moving (overwriting) $file to $JSON_DIR/"
  if ! mv -f "$file" "$JSON_DIR/"; then
    echo "Error: Failed to move $file to $JSON_DIR/"
    exit 1
  fi
done

# Step 4: Configure git for committing
git config --global user.email "azure-devops@yourdomain.com"
git config --global user.name "Azure DevOps Pipeline"

# Step 5: Add and commit the new JSON files
cd "$REPO_DIR"
for file in $JSON_FILES; do
  git add "json/$file"
done
TIMESTAMP=$(date +%Y%m%d%H%M%S)
git commit -m "Add $ENV_GROUP JSON files to json folder ($TIMESTAMP)"

# Step 6: Push the new JSON files to the repository
if ! git push origin HEAD:"$BRANCH_NAME"; then
  echo "Error: Failed to push $ENV_GROUP JSON files to branch $BRANCH_NAME."
  exit 1
fi
