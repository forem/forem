#!/bin/sh
set -e
# sync this fork with upstream to get the latest changes
git remote add upstream https://github.com/thepracticaldev/dev.to
git fetch upstream
git checkout master
git merge upstream/master

