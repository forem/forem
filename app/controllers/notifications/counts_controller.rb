class Notifications::CountsController < ApplicationController
  skip_before_action :ensure_signup_complete
  def index
    count = GetUnseenNotificationsService.new(current_user).get
    render plain: count.to_s
  end
end
