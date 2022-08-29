module Api
  module V1
    class FollowersController < ApiController
      include Api::FollowersController

      before_action :authenticate_with_api_key_or_current_user!
      before_action -> { limit_per_page(default: 80, max: 1000) }
    end
  end
end
