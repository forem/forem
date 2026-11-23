module Api
  module V0
    module Admin
      class UsersController < ApiController
        include Api::Admin::UsersController

        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        skip_csrf_unless_cookie_authenticated only: %i[create]
      end
    end
  end
end
