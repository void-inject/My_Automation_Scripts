#!/usr/bin/env bash

# Define the static file containing the list of paths to check
PATHS_FILE="${HOME}/paths.txt"

# Ensure the paths file exists
if [ ! -f "$PATHS_FILE" ]; then
    echo "Error: The file '$PATHS_FILE' does not exist."
    exit 1
fi

# Function to check if the local repository is behind the remote
check_and_pull() {

    echo " "
    echo "---------------------------"
    echo " "

    # Fetch the latest changes from the remote
    git fetch

    # Declare the behind variable separately
    local behind
    behind=$(git rev-list --count HEAD..origin/"$(git rev-parse --abbrev-ref HEAD)")

    if [ "$behind" -gt 0 ]; then
        echo "Local repository is behind the remote. Pulling changes..."
        git pull
    else
        echo "$repo_path: Up2Date"
    fi
    sleep 3
}

# Function to check for uncommitted changes and commit if found
check_and_commit() {
    local repo_path=$1

    # Navigate to the repo directory
    cd "$repo_path" || return

    # Check for any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes found in $repo_path"

        # Stage all changes and commit
        git add .
        git commit -m "auto-push"

        # Push changes to the remote repository
        git push

        # Call the function to check if the local copy is behind the remote
        check_and_pull "$repo_path"
    else
        echo "$repo_path: NoChange"

        # Call the function to check if the local copy is behind the remote
        check_and_pull "$repo_path"
    fi
}
#!/usr/bin/env bash

# Define the static file containing the list of paths to check
PATHS_FILE="${HOME}/paths.txt"

# Ensure the paths file exists
if [ ! -f "$PATHS_FILE" ]; then
    echo "Error: The file '$PATHS_FILE' does not exist."
    exit 1
fi

# Function to check if the local repository is behind the remote
check_and_pull() {

    echo " "
    echo "---------------------------"
    echo " "

    # Fetch the latest changes from the remote
    git fetch

    # Declare the behind variable separately
    local behind
    behind=$(git rev-list --count HEAD..origin/"$(git rev-parse --abbrev-ref HEAD)")

    if [ "$behind" -gt 0 ]; then
        echo "Local repository is behind the remote. Pulling changes..."
        git pull
    else
        echo "$repo_path: Up2Date"
    fi
    sleep 3
}

# Function to check for uncommitted changes and commit if found
check_and_commit() {
    local repo_path=$1

    # Navigate to the repo directory
    cd "$repo_path" || return

    # Check for any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes found in $repo_path"

        # Stage all changes and commit
        git add .
        git commit -m "auto-push"

        # Push changes to the remote repository
        git push

        # Call the function to check if the local copy is behind the remote
        check_and_pull "$repo_path"
    else
        echo "$repo_path: NoChange"

        # Call the function to check if the local copy is behind the remote
        check_and_pull "$repo_path"
    fi
}
