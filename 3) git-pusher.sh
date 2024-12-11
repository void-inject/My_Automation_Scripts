#!/usr/bin/env bash

# Define the static file containing the list of paths to check
PATHS_FILE="${HOME}/Public/scripts/paths.txt"

# Ensure the paths file exists
if [ ! -f "$PATHS_FILE" ]; then
    echo "Error: The file '$PATHS_FILE' does not exist."
    exit 1
fi

# Function to check if the local repository is behind the remote
check_and_pull() {
    local repo_path=$1
    echo "---------------------------"

    # Fetch the latest changes from the remote
    if ! git fetch; then
        echo "Error: Failed to fetch updates for $repo_path"
        return
    fi

    # Declare the behind variable separately
    local behind
    behind=$(git rev-list --count HEAD..origin/"$(git rev-parse --abbrev-ref HEAD)")

    if [ "$behind" -gt 0 ]; then
        echo "Local repository is behind the remote. Pulling changes..."
        if ! git pull; then
            echo "Error: Failed to pull changes for $repo_path"
        fi
    else
        echo "$repo_path: Up2Date"
    fi

    echo "---------------------------"
    sleep 3
}

# Function to check for uncommitted changes and commit if found
check_and_commit() {
    local repo_path=$1
    local commit_message=$2

    # Navigate to the repo directory
    cd "$repo_path" || return

    # Check for any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes found in $repo_path"

        # Stage all changes and commit
        git add .
        if ! git commit -m "$commit_message"; then
            echo "Error: Commit failed for $repo_path"
            return
        fi

        # Push changes to the remote repository
        if ! git push; then
            echo "Error: Push failed for $repo_path"
            return
        fi

        # Call the function to check if the local copy is behind the remote
        check_and_pull "$repo_path"
    else
        echo "$repo_path: NoChange"
        check_and_pull "$repo_path"
    fi
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

    commit_message="auto-push"

    # Call the function to check and commit for each directory
    check_and_commit "$path" "$commit_message"
done <"$PATHS_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Process completed."
