module Api
  module V0
    class UsersController < ApiController
      include Api::UsersController

      before_action :authenticate!, only: %i[me]
    end
  end
end
