module Api
  module V0
    class SubforemsController < ApiController
      include Api::SubforemsController

      before_action :set_cache_control_headers, only: %i[index]
    end
  end
end
