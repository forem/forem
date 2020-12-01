#!/bin/bash
set -e

echo "Restoring custom Travis config"
mv .travis.yml{.update_backup,}
