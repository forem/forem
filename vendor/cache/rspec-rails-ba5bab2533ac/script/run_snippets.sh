#!/bin/bash
set -e

(
  cd snippets
  # This is required to load `bundle/inline`
  unset RUBYOPT
  for snippet in *.rb;
  do
    echo Running $snippet
    ruby $snippet
  done
)
