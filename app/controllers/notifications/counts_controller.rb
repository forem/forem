module Notifications
  class CountsController < ApplicationMetalController
    before_action :current_user_by_token, only: [:index]

    def index
      user_id = session_current_user_id
      notifications = user_id ? Notification.where(user_id: user_id).from_subforem : Notification.none
      count = user_id ? notifications.unread.count : 0

      if params[:mode] == "detailed"
        most_recent = if user_id
                        notifications.select(:id, :read_at, :notified_at, :action)
                          .order(notified_at: :desc, created_at: :desc).first
                      end

        self.status = 200
        self.content_type = "application/json; charset=utf-8"
        self.response_body = {
          count: count,
          last_notification_id: most_recent&.id,
          read_at: most_recent&.read_at,
          notified_at: most_recent&.notified_at,
          action: most_recent&.action
        }.to_json
      else
        self.status = 200
        self.content_type = "text/plain; charset=utf-8"
        self.response_body = count.to_s
      end
    end
  end
end
