require 'bundler/setup'
require 'flipper'

stats = Flipper[:stats]

# Register group
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

# Some class that represents actor that will be trying to do something
class User
  attr_reader :id

  def initialize(id, admin)
    @id = id
    @admin = admin
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id

  def admin?
    @admin == true
  end
end

admin = User.new(1, true)
non_admin = User.new(2, false)

puts "Stats for admin: #{stats.enabled?(admin)}"
puts "Stats for non_admin: #{stats.enabled?(non_admin)}"

puts "\nEnabling Stats for admins...\n\n"
stats.enable_group :admins

puts "Stats for admin: #{stats.enabled?(admin)}"
puts "Stats for non_admin: #{stats.enabled?(non_admin)}"
