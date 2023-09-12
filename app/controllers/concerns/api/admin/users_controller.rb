module Api
  module Admin
    module UsersController
      extend ActiveSupport::Concern

      def create
        # NOTE: We can add an inviting user here, e.g. User.invite!(current_user, user_params).
        User.invite!(user_params.merge(registered: false))

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
