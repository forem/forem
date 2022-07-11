module Api
  module V1
    class UsersController < ApiController
      include Api::UsersController

      before_action :authenticate!
    end
  end
end
