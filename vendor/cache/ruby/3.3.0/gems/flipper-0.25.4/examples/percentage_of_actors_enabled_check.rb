require 'bundler/setup'
require 'flipper'

# Some class that represents what will be trying to do something
class User
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

# checking a bunch
total = 20_000
enabled = []
percentage_enabled = 10

feature = Flipper[:data_migration]
feature.enable_percentage_of_actors 10

(1..total).each do |id|
  user = User.new(id)
  if feature.enabled? user
    enabled << user
  end
end

p actual: enabled.size, expected: total * (percentage_enabled * 0.01)

# checking one
user = User.new(1)
p user_1_enabled: feature.enabled?(user)
