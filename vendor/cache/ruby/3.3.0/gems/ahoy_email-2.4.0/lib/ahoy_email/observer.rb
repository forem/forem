module AhoyEmail
  class Observer
    def self.delivered_email(message)
      AhoyEmail::Tracker.new(message).perform
    end
  end
end
