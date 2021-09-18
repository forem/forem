#!/usr/bin/env bash

gp env GEM_HOME=/workspace/.rvm
gp env GEM_PATH=/workspace/.rvm
gp env BUNDLE_PATH=/workspace/.rvm
eval $(gp env -e)

cp .env_sample .env
echo "APP_DOMAIN=\"$(gp url 3000 | cut -f 3 -d /)\"" >> .env
echo 'APP_PROTOCOL="https://"' >> .env
gem install solargraph
gem install foreman
bin/setup
