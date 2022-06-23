module Api
  module V0
    class ReadinglistController < ApiController
      include Api::ReadinglistController

      before_action :authenticate!
    end
  end
end
