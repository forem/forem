class Notifications::ReadsController < ApplicationController
  def create
    result = ""
    result = ReadNotificationsService.new(current_user).mark_as_read if current_user
    if params[:org_id] && user_belongs_to_org?
      org = Organization.find_by(id: params[:org_id])
      ReadNotificationsService.new(org).mark_as_read
    end
    current_user&.touch(:last_notification_activity)
    render plain: result
  end

  private

  def user_belongs_to_org?
    OrganizationMembership.exists?(user_id: current_user.id, organization_id: params[:org_id], type_of_user: %w[admin member])
  end
end
