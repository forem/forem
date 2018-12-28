module Notifications
  class ReadsController < ApplicationController
    def create
      result = ""
      result = ReadNotificationsService.new(current_user).mark_as_read if current_user
      current_user&.touch(:last_notification_activity)
      render plain: result
    end
  end
end
