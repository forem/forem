#!/usr/bin/env bash

if [ -n "$CODESPACE_NAME" ]; then
    echo "Running updates"

    # For some reason, Codespace prebuild also caches the codebase
    # at the time of prebuild. This means that if we don't run prebuild
    # on every single commit, the loaded codespace will not be on latest of
    # the chosen branch. This mitigates that.
    #
    # See https://github.com/orgs/community/discussions/58172
    
    # check if the branch is already up to date with git pull
    if git fetch origin $(git rev-parse --abbrev-ref HEAD) && git diff --quiet HEAD..origin/$(git rev-parse --abbrev-ref HEAD) ;then
        echo "Branch is already up to date"
    else
        echo "Branch is not up to date, pulling latest code"
        git pull origin $(git rev-parse --abbrev-ref HEAD) --no-rebase
        echo "Updating dependencies"
        dip provision
    fi

fi

cat <<EOF

  ______ ____  _____  ______ __  __ 
 |  ____/ __ \|  __ \|  ____|  \/  |
 | |__ | |  | | |__) | |__  | \  / |
 |  __|| |  | |  _  /|  __| | |\/| |
 | |   | |__| | | \ \| |____| |  | |
 |_|    \____/|_|  \_\______|_|  |_|

Setup complete! You can now run the server with 'rails s'
For more commands, run 'dip ls' or see the README.md

Happy coding!
EOF