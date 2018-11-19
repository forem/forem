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
      @notifications = Notification.where(user_id: current_user.id).order("created_at DESC").limit(500).to_a
      aggregate_notifications("Follow")
      aggregate_notifications("Reaction")
      @notifications = NotificationDecorator.decorate_collection(@notifications)[0..50]
      @last_user_reaction = @user.reactions.pluck(:id).last
      @last_user_comment = @user.comments.pluck(:id).last
    end
  end

  private

  def aggregate_notifications(notifiable_type)
    notification_struct = Struct.new(:grouped_notifications, :notifiable_type, :read?)
    notifications_to_aggregate = @notifications.select { |notification| notification.notifiable_type == notifiable_type }
    aggregation_types = notifications_to_aggregate.map(&:aggregation_format).uniq
    aggregation_types.each do |type|
      matched_notifications = notifications_to_aggregate.select { |notification| type == notification.aggregation_format }
      any_read = matched_notifications.count(&:read?).positive?
      notification_group = notification_struct.new(matched_notifications, notifiable_type, any_read)
      @notifications[@notifications.index(matched_notifications[0])] = notification_group unless @notifications.index(matched_notifications[0]).nil?
      matched_notifications[1..-1].each { |notification| @notifications[@notifications.index(notification)] = nil }
    end
    @notifications.compact!
  end
end
