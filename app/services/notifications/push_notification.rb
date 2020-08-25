module PushNotifications
  class Send
    def initialize(channels, payload)
      @channels = channels
      @payload = payload
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64

      Pusher::PushNotifications.publish_to_interests(
        interests: channels,
        payload: push_notification_payload,
      )
    end

    private

    attr_reader :channels, :payload

    def push_notification_payload
      title = "@#{payload.user.username}"
      subtitle = "re: #{payload.parent_or_root_article.title.strip}"

      case payload.class.name
      when "Comment"
        url_path = "comments"
      when "ListingEndorsement"
        url_path = "endorsements"
      end

      data_payload = { url: URL.url("/notifications/#{url_path}") }
      {
        apns: {
          aps: {
            alert: {
              title: title,
              subtitle: subtitle,
              body: CGI.unescapeHTML(payload.title.strip)
            }
          },
          data: data_payload
        },
        fcm: {
          notification: {
            title: title,
            body: subtitle
          },
          data: data_payload
        }
      }
    end
  end
end
