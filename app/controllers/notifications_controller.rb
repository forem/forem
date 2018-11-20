class NotificationsController < ApplicationController
  # No authorization required because we provide authentication on notifications page
  def index
    if user_signed_in?
      @notifications_index = true
      @user = if params[:username] && current_user.admin?
                User.find_by_username(params[:username])
              else
                current_user
              end
      if params[:filter].to_s.downcase == "posts"
        @notifications = NotificationDecorator.
        decorate_collection(Notification.where(user_id: current_user.id, notifiable_type: "Article", action: "Published").
        order("notified_at DESC").limit(55).to_a)
      elsif params[:filter].to_s.downcase == "comments"
        @notifications = NotificationDecorator.
        decorate_collection(Notification.where(user_id: current_user.id, notifiable_type: "Comment").
        order("notified_at DESC").limit(55).to_a)
      else
        @notifications = NotificationDecorator.
        decorate_collection(Notification.where(user_id: current_user.id).
        order("notified_at DESC").limit(55).to_a)
      end
      @last_user_reaction = @user.reactions.last&.id
      @last_user_comment = @user.comments.last&.id
    end
  end

  private
end
