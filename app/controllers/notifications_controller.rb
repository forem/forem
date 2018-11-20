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
      @notifications = NotificationDecorator.
        decorate_collection(Notification.where(user_id: current_user.id).
        order("notified_at DESC").limit(60).to_a)
      @last_user_reaction = @user.reactions.last&.id
      @last_user_comment = @user.comments.last&.id
    end
  end

  private
end
