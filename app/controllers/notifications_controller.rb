class NotificationsController < ApplicationController
  # No authorization required because we provide authentication on notifications page
  def index
    return unless user_signed_in?

    @notifications_index = true
    @user = user_to_view
    if params[:page]
      num = 45
      notified_at_offset = Notification.find(params[:page])&.notified_at
    else
      num = 8
    end
    @notifications = if (params[:org_id].present? || params[:filter] == "org") && allowed_user?
                       organization_notifications
                     elsif params[:org_id].blank? && params[:filter].present?
                       filtered_notifications
                     else
                       Notification.where(user_id: @user.id).order("notified_at DESC")
                     end
    @last_user_reaction = @user.reactions.last&.id
    @last_user_comment = @user.comments.last&.id
    @notifications = @notifications.where("notified_at < ?", notified_at_offset) if notified_at_offset
    @notifications = NotificationDecorator.decorate_collection(@notifications.limit(num))
    @organizations = @user.member_organizations if @user.organizations
    render partial: "notifications_list" if notified_at_offset
  end

  private

  def user_to_view
    if params[:username] && current_user.admin?
      User.find_by(username: params[:username])
    else
      current_user
    end
  end

  def filtered_notifications
    if params[:filter].to_s.casecmp("posts").zero?
      Notification.where(user_id: @user.id, notifiable_type: "Article", action: "Published").
        order("notified_at DESC")
    elsif params[:filter].to_s.casecmp("comments").zero?
      Notification.where(user_id: @user.id, notifiable_type: "Comment", action: nil). # Nil action means not reaction in this context
        or(Notification.where(user_id: @user.id, notifiable_type: "Mention")).
        order("notified_at DESC")
    end
  end

  def organization_notifications
    if params[:filter].to_s.casecmp("comments").zero?
      Notification.where(organization_id: params[:org_id], notifiable_type: "Comment", action: nil, user_id: nil). # Nil action means not reaction in this context
        or(Notification.where(organization_id: params[:org_id], notifiable_type: "Mention", user_id: nil)).
        order("notified_at DESC")
    else
      Notification.where(organization_id: params[:org_id], user_id: nil).
        order("notified_at DESC")
    end
  end

  def allowed_user?
    @user.organization_id == params[:org_id] || @user.admin?
  end
end
