module Api
  module V0
    class TrendsController < ApiController
      include Api::TrendsController

      before_action :find_trend, only: %i[show articles]
      before_action :set_cache_control_headers, only: %i[index show articles]
    end
  end
end
