module Api
  module V0
    class HealthChecksController < ApiController
      include Api::HealthChecksController

      before_action :authenticate_with_token
    end
  end
end
