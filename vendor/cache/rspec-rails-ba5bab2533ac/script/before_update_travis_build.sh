#!/bin/bash
set -e

echo "Backing up custom Travis config"
mv .travis.yml{,.update_backup}
