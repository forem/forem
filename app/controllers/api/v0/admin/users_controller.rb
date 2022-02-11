module Api
  module V0
    module Admin
      class UsersController < ApiController
        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        skip_before_action :verify_authenticity_token, only: %i[create]

        def create
          # NOTE: We can add an inviting user here, e.g. User.invite!(current_user, user_params).
          User.invite!(user_params)

          head :ok
        end

        private

        # Given that we expect creators to use tools (e.g. their existing SSO,
        # Zapier, etc) to post to this endpoint I wanted to keep the param
        # structure as simple and flat as possible, hence slightly more manual
        # param handling.
        #
        # NOTE: username is required for the validations on User to succeed.
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
