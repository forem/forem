module Rpush
  module Daemon
    module Wns
      class PostRequest
        def self.create(notification, access_token)
          stringify_keys(notification.data) unless notification.data.nil?

          if raw_notification?(notification)
            RawRequest.create(notification, access_token)
          elsif badge_notification?(notification)
            BadgeRequest.create(notification, access_token)
          else
            ToastRequest.create(notification, access_token)
          end
        end

        private_class_method

        def self.raw_notification?(notification)
          notification.class.name.match(/RawNotification/)
        end

        def self.badge_notification?(notification)
          notification.class.name.match(/BadgeNotification/)
        end

        def self.stringify_keys(data)
          data.keys.each { |key| data[key.to_s || key] = data.delete(key) }
        end
      end
    end
  end
end
