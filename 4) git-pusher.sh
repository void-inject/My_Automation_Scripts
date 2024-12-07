#!/usr/bin/env bash

# Define the static file containing the list of paths to check
PATHS_FILE="paths.txt"

# Ensure the paths file exists
if [ ! -f "$PATHS_FILE" ]; then
    echo "Error: The file '$PATHS_FILE' does not exist."
    exit 1
fi

# Function to check if the local repository is behind the remote
check_and_pull() {
    local repo_path=$1
    echo "Checking if local repository is behind the remote at: $repo_path"

    # Navigate to the repo directory
    cd "$repo_path" || return

    # Fetch the latest changes from the remote
    git fetch

    # Declare the behind variable separately
    local behind
    behind=$(git rev-list --count HEAD..origin/"$(git rev-parse --abbrev-ref HEAD)")

    if [ "$behind" -gt 0 ]; then
        echo "Local repository is behind the remote. Pulling changes..."
        git pull
    else
        echo "Local repository is up-to-date with the remote."
    fi

    echo "-------------------------------------"
}

# Function to check for uncommitted changes and commit if found
check_and_commit() {
    local repo_path=$1
    echo "Checking repository at: $repo_path"

    # Navigate to the repo directory
    cd "$repo_path" || return

    # Check for any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes found in $repo_path"

        # Show the changes before asking for the commit message
        echo "The following changes have been made:"
        git diff --color=auto
        echo "-------------------------------------"

        # Ask for commit message
        read -pr "Enter commit message: " commit_message

        # Stage all changes and commit
        git add .
        git commit -m "$commit_message"

        # Push changes to the remote repository
        git push
        echo "Changes pushed to remote repository."
    else
        echo "No uncommitted changes in $repo_path"
    fi

    echo "-------------------------------------"
}

# Read each path from the static paths file and check commits for that path
while IFS= read -r path; do
    # Skip empty lines
    if [ -z "$path" ]; then
        continue
    fi

    # Expand the path if it contains ~ (home directory)
    path=$(eval echo "$path")

    # Check if the path exists
    if [ ! -d "$path" ]; then
        echo "Warning: The path '$path' does not exist."
        continue
    fi

    # Call the function to check if the local copy is behind the remote
    check_and_pull "$path"

    # Call the function to check and commit for each directory
    check_and_commit "$path"
done <"$PATHS_FILE"

echo "Process completed."
