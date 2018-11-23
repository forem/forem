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
      if params[:page]
        num = 45
        notified_at_offset = Notification.find(params[:page])&.notified_at
      else
        num = 10
      end
      if params[:filter].to_s.downcase == "posts"
        @notifications = Notification.where(user_id: current_user.id, notifiable_type: "Article", action: "Published").
        order("notified_at DESC")
      elsif params[:filter].to_s.downcase == "comments"
        @notifications = Notification.where(user_id: current_user.id, notifiable_type: "Comment", action: nil). # Nil action means not reaction in this context
        or(Notification.where(user_id: current_user.id, notifiable_type: "Mention")).
        order("notified_at DESC")
      else
        @notifications = Notification.where(user_id: current_user.id).
        order("notified_at DESC")
      end
      @last_user_reaction = @user.reactions.last&.id
      @last_user_comment = @user.comments.last&.id
      @notifications = @notifications.where("notified_at < ?", notified_at_offset) if notified_at_offset
      @notifications = NotificationDecorator.decorate_collection(@notifications.limit(num))
      render partial: "notifications_list" if notified_at_offset
    end
  end

  private
end
