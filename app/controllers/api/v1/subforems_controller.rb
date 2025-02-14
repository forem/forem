module Api
  module V1
    class SubforemsController < ApiController
      include Api::SubforemsController

      before_action :set_cache_control_headers, only: %i[index]
    end
  end
end
