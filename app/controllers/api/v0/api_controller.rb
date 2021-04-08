module Api
  module V0
    class ApiController < ApplicationController
      protect_from_forgery with: :exception, prepend: true

      include ValidRequest

      respond_to :json

      rescue_from ActionController::ParameterMissing do |exc|
        error_unprocessable_entity(exc.message)
      end

      rescue_from ActiveRecord::RecordInvalid do |exc|
        error_unprocessable_entity(exc.message)
      end

      rescue_from ActiveRecord::RecordNotFound, with: :error_not_found

      rescue_from Pundit::NotAuthorizedError, with: :error_unauthorized

      protected

      def error_unprocessable_entity(message)
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end

      def error_unauthorized
        render json: { error: "unauthorized", status: 401 }, status: :unauthorized
      end

      def error_not_found
        render json: { error: "not found", status: 404 }, status: :not_found
      end

      def authenticate!
        @user = authenticated_user
        return error_unauthorized unless @user && !@user.suspended?
      end

      def authorize_super_admin
        error_unauthorized unless @user.has_role?(:super_admin)
      end

      # Checks if the user is authenticated, sets @user to nil otherwise
      def authenticate_with_api_key_or_current_user
        @user = authenticate_with_api_key || current_user
      end

      # Checks if the user is authenticated, if so sets the variable @user
      # Returns HTTP 401 Unauthorized otherwise
      def authenticate_with_api_key_or_current_user!
        @user = authenticate_with_api_key || current_user
        error_unauthorized unless @user
      end

      private

      def authenticate_with_api_key
        api_key = request.headers["api-key"]
        return unless api_key

        api_secret = ApiSecret.includes(:user).find_by(secret: api_key)
        return unless api_secret

        # guard against timing attacks
        # see <https://www.slideshare.net/NickMalcolm/timing-attacks-and-ruby-on-rails>
        secure_secret = ActiveSupport::SecurityUtils.secure_compare(api_secret.secret, api_key)
        return api_secret.user if secure_secret
      end

      def authenticated_user
        if doorkeeper_token
          User.find(doorkeeper_token.resource_owner_id)
        elsif request.headers["api-key"]
          authenticate_with_api_key
        elsif current_user
          current_user
        end
      end
    end
  end
end
