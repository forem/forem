module Api
  module V1
    class ReadinglistController < ApiController
      include Api::ReadinglistController

      before_action :authenticate!
    end
  end
end
