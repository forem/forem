#!/usr/bin/env bash

if [ -n "$CODESPACE_NAME" ]; then
    # CODESPACE is set, perform your file changes here
    echo "eval $(dip console)" >> ~/.bashrc
    echo "eval $(dip console)" >> ~/.zshrc
    echo "CODESPACE environment variable is set. Performing file changes..."

    cp .env_sample .env
    echo "APP_DOMAIN=\"$CODESPACE_NAME-3000.app.github.dev\"" >> .env
    echo 'APP_PROTOCOL="https://"' >> .env
    echo "File changes completed."
else
    echo "CODESPACE environment variable is not set. No file changes performed."
fi
