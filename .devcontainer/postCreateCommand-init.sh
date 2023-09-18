#!/usr/bin/env bash

# This is intentionally separate from .devcontainer/onCreateCommand-init.sh
# because $CODESPACE_NAME is not available at that point in time.

if [ ! -f .env ]; then
    echo "Creating .env file"
    cp .env_sample .env
fi

echo "Updating .env file with codespace specific values"
sed -i "s/APP_DOMAIN=.*/APP_DOMAIN=$CODESPACE_NAME-3000.app.github.dev/g" .env
sed -i "s/APP_PROTOCOL=.*/APP_PROTOCOL=https:\/\//g" .env