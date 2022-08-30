module Api
  module V1
    class UsersController < ApiController
      include Api::UsersController

      before_action :authenticate_with_api_key!, only: %i[me suspend unpublish]
    end
  end
end
