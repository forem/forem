require 'bundler/setup'
require 'flipper'

# sets up default adapter so Flipper works like Flipper::DSL
Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Memory.new }
end

puts Flipper.enabled?(:search) # => false
Flipper.enable(:search)
puts Flipper.enabled?(:search) # => true
Flipper.disable(:search)

enabled_actor = Flipper::Actor.new("1")
disabled_actor = Flipper::Actor.new("2")
Flipper.enable_actor(:search, enabled_actor)

puts Flipper.enabled?(:search, enabled_actor)
puts Flipper.enabled?(:search, disabled_actor)
