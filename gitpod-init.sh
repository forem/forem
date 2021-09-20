#!/usr/bin/env bash

echo "Installing the GitHub CLI"
brew install gh

cp .env_sample .env
echo "APP_DOMAIN=\"$(gp url 3000 | cut -f 3 -d /)\"" >> .env
echo 'APP_PROTOCOL="https://"' >> .env
gem install solargraph
gem install foreman
bin/setup
