module Notifications
  class CountsController < ApplicationController
    before_action :current_user_by_token, only: [:show]

    def index
      notifications = current_user ? current_user.notifications.from_subforem : Notification.none
      count = current_user ? notifications.unread.count : 0

      if params[:mode] == "detailed"
        most_recent = notifications.order(notified_at: :desc, created_at: :desc).first
        
        render json: { 
          count: count, 
          last_notification_id: most_recent&.id,
          last_read_at: most_recent&.read_at,
          notified_at: most_recent&.notified_at,
          action: most_recent&.action
        }
      else
        render plain: count.to_s
      end
    end
  end
end
