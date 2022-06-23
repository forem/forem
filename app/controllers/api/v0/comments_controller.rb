module Api
  module V0
    class CommentsController < ApiController
      include Api::CommentsController

      before_action :set_cache_control_headers, only: %i[index show]
    end
  end
end
