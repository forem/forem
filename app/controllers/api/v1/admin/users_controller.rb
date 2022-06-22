module Api
  module V1
    module Admin
      class UsersController < ApiController
        include Api::Admin::UsersController

        before_action :authenticate!
        before_action :authorize_super_admin
      end
    end
  end
end
