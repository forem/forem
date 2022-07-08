module Api
  module V1
    class ApiController < ApplicationController
      # Custom MIME Type - /config/initializers/mime_types.rb
      respond_to :api_v1

      self.api_action = true

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

      # @note This method is performing both authentication and authorization.  The user suspended
      #       should be something added to the corresponding pundit policy.
      def authenticate!
        @user = authenticate_with_api_key
        return error_unauthorized unless @user
        return error_unauthorized if @user.suspended?

        true
      end

      def authorize_super_admin
        error_unauthorized unless @user.super_admin?
      end

      private

      # @note By default pundit_user is an alias of "#current_user".  However, as "#current_user"
      #       only tells part of the story, we need to roll our own.  That means checking if we have
      #       `@user` (which is set in #authenticate_with_api_key) but if that's not
      #       present, call the method.
      #
      # @return [User, NilClass]
      #
      # @note [@jeremyf] is choosing to reference the instance variable (e.g. `@user`) and if that's
      #       nil to call the `authenticate_with_api_key`.  This way I'm not
      #       altering the implementation details of the `authenticate_with_api_key`
      #       function by introducing memoization.
      #
      # @see #authenticate_with_api_key
      def pundit_user
        # What's going on here?
        @pundit_user ||= @user
      end

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
    end
  end
end
