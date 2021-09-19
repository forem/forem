#!/usr/bin/env bash

gp env GEM_HOME=/workspace/.rvm
gp env GEM_PATH=/workspace/.rvm
gp env BUNDLE_PATH=/workspace/.rvm
eval $(gp env -e)
bin/startup
