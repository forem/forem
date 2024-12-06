# frozen_string_literal: true

require "redis/connection/registry"

# If a connection driver was required before this file, the array
# Redis::Connection.drivers will contain one or more classes. The last driver
# in this array will be used as default driver. If this array is empty, we load
# the plain Ruby driver as our default. Another driver can be required at a
# later point in time, causing it to be the last element of the #drivers array
# and therefore be chosen by default.
require_relative "connection/ruby" if Redis::Connection.drivers.empty?
