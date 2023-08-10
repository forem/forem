#!/usr/bin/env bash

ln -s "$(which ruby)" "$(rvm gemdir)/bin/ruby"
cp .env_sample .env
echo "APP_DOMAIN=\"$(gp url 3000 | cut -f 3 -d /)\"" >> .env
echo 'APP_PROTOCOL="https://"' >> .env
gem install solargraph
gem install foreman
bin/setup
