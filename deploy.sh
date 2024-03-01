#!/bin/sh

# Set the repository and branch as environment variables
repository="$REPO"
branch="$BRANCH"
token="$AUTH"
repo_name=$(basename "$repository" .git)

# SWITCH WORKING DIR
cd "/app" || { echo "Failed to change to repository directory"; exit 1; }

# Clone the repository if it doesn't exist
git clone "https://$token@github.com/$repository.git" "/repo" || { echo "Failed to clone repository"; exit 1; }

# Change to the repository directory
cd "/repo" || { echo "Failed to change to repository directory"; exit 1; }

# Checkout the specified branch
git checkout "$branch" || { echo "Failed to checkout branch"; exit 1; }

# Run any additional commands or scripts here
image_name="$repo_name:$branch"
docker build -t "$image_name" .
docker run -d -p 3000:3000 "$image_name"

# Exit successfully
exit 0
