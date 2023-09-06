#!/usr/bin/env bash

if [ -n "$CODESPACE" ]; then
    # CODESPACE is set, perform your file changes here
    echo "CODESPACE environment variable is set. Performing file changes..."

    cp .env_sample .env
    echo "APP_DOMAIN=\"$CODESPACE.app.github.dev\"" >> .env
    echo 'APP_PROTOCOL="https://"' >> .env
    echo "File changes completed."
else
    echo "CODESPACE environment variable is not set. No file changes performed."
fi
gem install dip
dip provision
