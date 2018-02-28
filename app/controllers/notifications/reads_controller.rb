class Notifications::ReadsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :ensure_signup_complete
  def create
    result = ""
    result = ReadNotificationsService.new(current_user).mark_as_read if current_user
    current_user&.touch(:last_notification_activity)
    render plain: result
  end
end
