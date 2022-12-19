module Api
  module V1
    class ReadinglistController < ApiController
      include Api::ReadinglistController

      before_action :authenticate_with_api_key!
    end
  end
end
