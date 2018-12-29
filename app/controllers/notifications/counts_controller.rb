class Notifications::CountsController < ApplicationController
  def index
    count = GetUnseenNotificationsService.new(current_user).get
    render plain: count.to_s
  end
end
