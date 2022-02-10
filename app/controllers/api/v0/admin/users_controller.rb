module Api
  module V0
    module Admin
      class UsersController < ApiController
        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        skip_before_action :verify_authenticity_token, only: %i[create]

        def create
          User.invite!(user_params)

          head :ok
        end

        private

        def user_params
          {
            email: params.require(:email),
            name: params[:name],
            username: params[:email]
          }.compact_blank
        end
      end
    end
  end
end
