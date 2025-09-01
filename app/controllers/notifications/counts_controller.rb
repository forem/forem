module Notifications
  class CountsController < ApplicationController
    before_action :current_user_by_token, only: [:show]

    def index
      count = current_user ? current_user.notifications.unread.from_subforem.count : 0
      render plain: count.to_s
    end
  end
end
