class Notifications::ReadsController < ApplicationController
  def create
    result = ""
    result = ReadNotificationsService.new(current_user).mark_as_read if current_user
    if params[:org_id] && current_user.org_member?(params[:org_id])
      org = Organization.find_by(id: params[:org_id])
      ReadNotificationsService.new(org).mark_as_read
    end
    current_user&.touch(:last_notification_activity)
    render plain: result
  end
end
