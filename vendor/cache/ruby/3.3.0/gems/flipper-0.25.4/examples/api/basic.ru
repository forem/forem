#
# Usage:
#   # if you want it to not reload and be really fast
#   bin/rackup examples/api/basic.ru -p 9999
#
#   # if you want reloading
#   bin/shotgun examples/api/basic.ru -p 9999
#
#   http://localhost:9999/
#

require 'bundler/setup'
require "flipper/api"
require "flipper/adapters/pstore"

# You can uncomment this to get some default data:
# Flipper.enable :logging

run Flipper::Api.app
