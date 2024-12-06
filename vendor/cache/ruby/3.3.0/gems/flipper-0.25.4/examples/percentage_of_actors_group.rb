# This example shows how to setup a group that enables a feature for a
# percentage of actors. It could be combined with other logic to enable a
# feature for actors in a particular location or on a particular plan, but only
# for a percentage of them. The percentage is a constant, but could easily be
# plucked from memcached, redis, mysql or whatever.
require 'bundler/setup'
require 'flipper'

# Some class that represents what will be trying to do something
class User < Struct.new(:id)
  include Flipper::Identifier
end

PERCENTAGE = 50
Flipper.register(:experimental) do |actor|
  if actor.respond_to?(:flipper_id)
    Zlib.crc32(actor.flipper_id.to_s) % 100 < PERCENTAGE
  else
    false
  end
end

# enable the experimental group
Flipper.enable_group :stats, :experimental

# create a bunch of fake users and see how many are enabled
total = 10_000
users = (1..total).map { |n| User.new(n) }
enabled = users.map { |user|
  Flipper.enabled?(:stats, user) ? true : nil
}.compact

# show the results
actual = (enabled.size / total.to_f * 100).round
puts "percentage: #{actual} vs hoped for: #{PERCENTAGE}"
