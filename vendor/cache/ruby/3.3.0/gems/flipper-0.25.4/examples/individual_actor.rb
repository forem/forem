require 'bundler/setup'
require 'flipper'

stats = Flipper[:stats]

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

user1 = User.new(1)
user2 = User.new(2)

puts "Stats for user1: #{stats.enabled?(user1)}"
puts "Stats for user2: #{stats.enabled?(user2)}"

puts "\nEnabling stats for user1...\n\n"
stats.enable(user1)

puts "Stats for user1: #{stats.enabled?(user1)}"
puts "Stats for user2: #{stats.enabled?(user2)}"
