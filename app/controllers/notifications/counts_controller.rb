module Notifications
  class CountsController < ApplicationController
    def index
      count = current_user ? current_user.notifications.unread.count : 0
      render plain: count.to_s
    end
  end
end
