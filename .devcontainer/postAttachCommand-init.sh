#!/usr/bin/env bash

# For some reason, Codespace prebuild also caches the codebase
# at the time of prebuild. This means that if we don't run prebuild
# on every single commit, the loaded codespace will not be on latest of
# the chosen branch. This mitigates that.
#
# See https://github.com/orgs/community/discussions/58172
if [ -n "$CODESPACE_NAME" ]; then
    git pull origin $(git rev-parse --abbrev-ref HEAD)
    provision
fi
