#!/bin/bash

# This script likely won't work as is for you, but is a good template for
# iterating over all rubies and regenerating HTML fixtures.

set -e

source /usr/local/share/chruby/chruby.sh

function switch_ruby() {
  chruby $1
}

function regen() {
  bundle check || bundle install
  GENERATE=1 bundle exec rspec ./spec/rspec/core/formatters/ || true
}

for ruby in \
  jruby-1.7.9 \
  1.9.3-p392 \
  2.0.0-p247 \
  2.1.0-p0 \
  rbx-2.2.3 \
  ree-1.8.7-2012.02;
do
  switch_ruby $ruby
  ruby -v
  if [ $(echo $ruby | grep jruby) ]
  then
    export JRUBY_OPTS=--1.8
    regen
    export JRUBY_OPTS=--1.9
    regen
  else
    regen
  fi
done

