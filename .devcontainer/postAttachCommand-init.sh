#!/usr/bin/env bash

if [ -n "$CODESPACE_NAME" ]; then
    echo "Running updates"

    # Github Codespace prebuild caches the codebase.
    # This means depending on the time the Codespace is created,
    # it may not be on latest commit with latest dependency changes
    #
    # See https://github.com/orgs/community/discussions/58172

    if git fetch origin "$(git rev-parse --abbrev-ref HEAD)" && git diff --quiet "HEAD..origin/$(git rev-parse --abbrev-ref HEAD)" ;then
        echo "Branch is already up to date"
    else
        echo "Branch is not up to date, pulling latest code"
        git pull origin "$(git rev-parse --abbrev-ref HEAD)" --no-rebase
        echo "Updating dependencies"
        bin/setup
    fi
fi

cat <<EOF

  ______ ____  _____  ______ __  __
 |  ____/ __ \|  __ \|  ____|  \/  |
 | |__ | |  | | |__) | |__  | \  / |
 |  __|| |  | |  _  /|  __| | |\/| |
 | |   | |__| | | \ \| |____| |  | |
 |_|    \____/|_|  \_\______|_|  |_|

Setup complete! You can now run the server with 'bin/startup'

Happy coding!
EOF
