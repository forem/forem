require 'bundler/setup'
require 'flipper'

# create a thing with an identifier
class Person < Struct.new(:id)
  include Flipper::Identifier
end

person = Person.new(1)

puts "Stats are disabled by default\n\n"

# is a feature enabled
puts "flipper.enabled? :stats: #{Flipper.enabled? :stats}"

# is a feature on or off for a particular person
puts "Flipper.enabled? :stats, person: #{Flipper.enabled? :stats, person}"

# get at a feature
puts "\nYou can also get an individual feature like this:\nstats = Flipper[:stats]\n\n"
stats = Flipper[:stats]

# is that feature enabled
puts "stats.enabled?: #{stats.enabled?}"

# is that feature enabled for a particular person
puts "stats.enabled? person: #{stats.enabled? person}"

# enable a feature by name
puts "\nEnabling stats\n\n"
Flipper.enable :stats

# or, you can use the feature to enable
stats.enable

puts "stats.enabled?: #{stats.enabled?}"
puts "stats.enabled? person: #{stats.enabled? person}"

# oh, no, let's turn this baby off
puts "\nDisabling stats\n\n"
Flipper.disable :stats

# or we can disable using feature obviously
stats.disable

puts "stats.enabled?: #{stats.enabled?}"
puts "stats.enabled? person: #{stats.enabled? person}"
puts

# get an instance of the percentage of time type set to 5
puts Flipper.time(5).inspect

# get an instance of the percentage of actors type set to 15
puts Flipper.actors(15).inspect

# get an instance of an actor using an object that responds to flipper_id
responds_to_flipper_id = Struct.new(:flipper_id).new(10)
puts Flipper.actor(responds_to_flipper_id).inspect

# get an instance of an actor using an object
thing = Struct.new(:flipper_id).new(22)
puts Flipper.actor(thing).inspect

# register a top level group
admins = Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}
puts admins.inspect

# get instance of registered group by name
puts Flipper.group(:admins).inspect
