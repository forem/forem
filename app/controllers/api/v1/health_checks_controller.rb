module Api
  module V1
    class HealthChecksController < ApiController
      include Api::HealthChecksController

      before_action :authenticate_with_token
    end
  end
end
