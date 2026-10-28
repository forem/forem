module Api
  module V0
    class CommentsController < ApiController
      include Api::CommentsController

      before_action :authenticate!, only: %i[preview]
      before_action :set_cache_control_headers, only: %i[index show]
      skip_before_action :verify_authenticity_token, only: %i[preview]
    end
  end
end
