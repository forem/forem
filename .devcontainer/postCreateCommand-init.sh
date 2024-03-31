#!/usr/bin/env bash

# This is intentionally separate from .devcontainer/onCreateCommand-init.sh
# because $CODESPACE_NAME is not available at that point in time.

echo HISTFILE="/usr/local/hist/.zsh_history" >> ~/.zshrc

if [ ! -f .env ]; then
    echo "Creating .env file"
    cp .env_sample .env
fi

if [ -n "$CODESPACE_NAME" ]; then
    echo "Updating .env file with codespace specific values"
    echo APP_DOMAIN="${CODESPACE_NAME}-3000.app.github.dev" >> .env
    echo APP_PROTOCOL=https:// >> .env
    echo COMMUNITY_NAME="DEV(codespace)" >> .env
fi
