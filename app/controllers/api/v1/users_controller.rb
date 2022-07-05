module Api
  module V1
    class UsersController < ApiController
      include Api::UsersController

      before_action :authenticate!
      before_action :authorize_super_admin
    end
  end
end
