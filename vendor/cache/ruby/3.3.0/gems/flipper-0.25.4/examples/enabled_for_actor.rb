require 'bundler/setup'
require 'flipper'

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id, admin)
    @id = id
    @admin = admin
  end

  def admin?
    @admin
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

user1 = User.new(1, true)
user2 = User.new(2, false)

Flipper.register :admins do |actor|
  actor.admin?
end

Flipper.enable :search
Flipper.enable_actor :stats, user1
Flipper.enable_percentage_of_actors :pro_stats, 50
Flipper.enable_group :tweets, :admins
Flipper.enable_actor :posts, user2

pp Flipper.features.select { |feature| feature.enabled?(user1) }.map(&:name)
pp Flipper.features.select { |feature| feature.enabled?(user2) }.map(&:name)
