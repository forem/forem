module Api
  module V1
    module Admin
      class UsersController < BaseController
        include Api::Admin::UsersController
      end
    end
  end
end
