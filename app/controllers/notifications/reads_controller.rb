class Notifications::ReadsController < ApplicationController
  def create
    result = ""
    result = ReadNotificationsService.new(current_user).mark_as_read if current_user
    ReadNotificationsService.new(current_user.organization).mark_as_read if params[:org_id]&.to_i && user_belongs_to_org?
    current_user&.touch(:last_notification_activity)
    render plain: result
  end

  private

  def user_belongs_to_org?
    # this can be changed later with roles
    current_user.organization_id == params[:org_id].to_i
  end
end
