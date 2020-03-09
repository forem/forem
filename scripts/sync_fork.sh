#!/bin/sh
set -e

URL="https://github.com/thepracticaldev/dev.to";

if ! git config remote.upstream.url > /dev/null; then
  echo "Adding remote ${URL}"
  git remote add upstream $URL
fi
git fetch upstream
git checkout master
git merge upstream/master
