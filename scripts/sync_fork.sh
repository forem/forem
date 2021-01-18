#!/bin/sh
set -e

# sync this fork with upstream to get the latest changes
URL="https://github.com/thepracticaldev/dev.to";
if ! git config remote.upstream.url > /dev/null; then
  echo "Adding remote ${URL}"
  git remote add upstream $URL
fi
git fetch upstream
git checkout main
git merge upstream/main
