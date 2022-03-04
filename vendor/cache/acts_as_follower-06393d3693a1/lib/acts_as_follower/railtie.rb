require 'rails'

module ActsAsFollower
  class Railtie < Rails::Railtie

    initializer "acts_as_follower.active_record" do |app|
      ActiveSupport.on_load :active_record do
        include ActsAsFollower::Follower
        include ActsAsFollower::Followable
      end
    end

  end
end
