module Notifications
  # Notifications an admin pushes through the admin API. Their content is plain
  # text plus an optional link, rendered by notifications/_adminnotification.
  module AdminNotifications
    NOTIFIABLE_TYPE = "AdminNotification".freeze
    MAX_RECIPIENTS = 1_000
    TITLE_LIMIT = 250
    BODY_LIMIT = 1_000
    URL_LIMIT = 2_000
    CONTENT_KEYS = %w[title body url].freeze

    def self.json_data(content, actor:)
      data = { admin_notification: content.slice(*CONTENT_KEYS) }
      data[:user] = Notifications.user_data(actor) if actor
      data
    end
  end
end
