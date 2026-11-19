#!/usr/bin/env bash

# Runs once after the container is created.  $CODESPACE_NAME and $ONA_ENVIRONMENT_NAME
# are available here, so environment-specific .env values are written now.

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
elif [ -n "$ONA_ENVIRONMENT_NAME" ]; then
    echo "Updating .env file with Ona specific values"
    echo APP_DOMAIN="${ONA_ENVIRONMENT_NAME}-3000.app.ona.dev" >> .env
    echo APP_PROTOCOL=https:// >> .env
    echo COMMUNITY_NAME="DEV(Ona)" >> .env
fi
