module Api
  module V1
    class CommentsController < ApiController
      include Api::CommentsController

      before_action :authenticate_with_api_key!, only: %i[preview]
      before_action :set_cache_control_headers, only: %i[index show]
    end
  end
end
