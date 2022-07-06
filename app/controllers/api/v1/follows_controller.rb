module Api
  module V1
    class FollowsController < ApiController
      include Api::FollowsController

      before_action :authenticate!
    end
  end
end
