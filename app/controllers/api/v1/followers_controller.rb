module Api
  module V1
    class FollowersController < ApiController
      include Api::FollowersController

      before_action :authenticate!
      before_action -> { limit_per_page(default: 80, max: 1000) }
    end
  end
end
