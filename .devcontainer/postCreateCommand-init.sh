#!/usr/bin/env bash

if [ -n "$CODESPACE_NAME" ]; then
    # Inject dip console into bashrc
    line_to_insert='eval "$(dip console)"'
    echo "$line_to_insert" >> ~/.bashrc

    # Add codespace specific environment variables
    cp .env_sample .env
    echo "APP_DOMAIN=\"$CODESPACE_NAME-3000.app.github.dev\"" >> .env
    echo 'APP_PROTOCOL="https://"' >> .env
    echo "File changes completed."
else
    echo "CODESPACE environment variable is not set. No file changes performed."
fi
