#!/bin/sh
set -e
# clean up the fork and restart from upstream
git remote add upstream https://github.com/thepracticaldev/dev.to
git fetch upstream
git checkout master
git reset --hard upstream/master  
git push origin master --force 
