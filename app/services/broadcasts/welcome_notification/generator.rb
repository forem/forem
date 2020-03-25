# Generates a broadcast to be delivered as a notification.
module Broadcasts
  module WelcomeNotification
    module Generator
      def self.call(user_id)
        user = User.find(user_id)

        Introduction.send(user)
        # Authentication.send(user)
        # CustomizeFeed.send(user)
        # CustomizeExperience.send(user)
      end
    end
  end
end
