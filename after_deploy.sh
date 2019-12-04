#!/bin/bash

REPOSITORY=https://github.com/thepracticaldev/dev.to_private/
REVISION="$(git rev-parse HEAD)"
COMMIT_AUTHOR=$(git --no-pager log -1 --pretty=format:'%an')
PAYLOAD='{ "environment":"production", "repository":"'${REPOSITORY}'", "revision":"'${REVISION}'", "username":"'${COMMIT_AUTHOR}'"}'
