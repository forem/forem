module Api
  module V0
    class VideosController < ApiController
      include Api::VideosController

      before_action :set_cache_control_headers, only: %i[index]
    end
  end
end
