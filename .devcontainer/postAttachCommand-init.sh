#!/usr/bin/env bash

# Exit status of bin/setup when this hook ran it; empty when it did not run.
setup_status=""

if [ -n "$CODESPACE_NAME" ] || [ -n "$ONA_ENVIRONMENT_NAME" ]; then
    echo "Running updates"

    # Github Codespace/Ona prebuild caches the codebase.
    # This means depending on the time the environment is created,
    # it may not be on latest commit with latest dependency changes

    # Fetch into a ref only this hook uses: FETCH_HEAD is shared, so another fetch could overwrite it.
    fetch_ref="refs/postattach/$$"
    trap 'git update-ref -d "$fetch_ref" 2>/dev/null || true' EXIT

    branch="$(git symbolic-ref --quiet --short HEAD)"
    if [ -z "$branch" ]; then
        # A detached checkout (a pinned commit or tag) would resolve to `git pull origin HEAD`
        # and silently move you off that commit, so leave it alone.
        echo "Detached HEAD at $(git rev-parse --short HEAD); not pulling"
    elif ! git fetch origin "+refs/heads/$branch:$fetch_ref" ||
        ! fetched="$(git rev-parse --verify --quiet "$fetch_ref^{commit}")"; then
        echo "Could not fetch origin/$branch; not updating"
    elif [ "$(git symbolic-ref --quiet --short HEAD)" != "$branch" ]; then
        # The checkout changed while the fetch ran (a pin or another branch); do not touch it.
        echo "Checkout changed from $branch during the fetch; not updating"
    elif git merge-base --is-ancestor "$fetched" HEAD; then
        echo "Branch is already up to date"
    elif [ "$(git symbolic-ref --quiet --short HEAD)" != "$branch" ]; then
        # Revalidate immediately before merging in case the checkout changed during merge-base.
        echo "Checkout changed from $branch before merge; not updating"
    else
        echo "Branch is not up to date, merging the fetched origin/$branch"
        # Merge the commit resolved above, not a second `git pull`, so it cannot change in between.
        if git merge --no-edit "$fetched"; then
            echo "Updating dependencies"
            bin/setup
            setup_status=$?
        else
            echo "Could not merge origin/$branch; resolve it, then run 'bin/setup'"
        fi
    fi
fi

cat <<EOF

  ______ ____  _____  ______ __  __
 |  ____/ __ \|  __ \|  ____|  \/  |
 | |__ | |  | | |__) | |__  | \  / |
 |  __|| |  | |  _  /|  __| | |\/| |
 | |   | |__| | | \ \| |____| |  | |
 |_|    \____/|_|  \_\______|_|  |_|

EOF

if [ "$setup_status" = "0" ]; then
    printf "Setup complete! You can now run the server with 'bin/startup'\n\nHappy coding!\n"
elif [ -n "$setup_status" ]; then
    printf "bin/setup failed (exit %s). Fix the error above, run 'bin/setup' again,\nthen start the server with 'bin/startup'.\n" "$setup_status"
elif bundle check >/dev/null 2>&1 && [ -f node_modules/.yarn-state.yml ]; then
    # node_modules is a named volume, so the directory can exist and be empty.  Yarn writes
    # .yarn-state.yml only after it links packages.  The database is not checked here.
    printf "Gems and JavaScript packages are installed. Start the server with 'bin/startup'\n(run 'bin/setup' first if the database is not set up yet).\n"
else
    printf "Next: run 'bin/setup' to install dependencies and prepare the database,\nthen start the server with 'bin/startup'.\n"
fi
