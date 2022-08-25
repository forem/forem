module Api
  module V0
    class ApiController < ApplicationController
      protect_from_forgery with: :exception, prepend: true

      include ValidRequest

      respond_to :json

      # Informs the application that all actions taking by this controller (and it's subclasses) are
      # considered an api_action.
      self.api_action = true

      after_action :add_deprecation_warning_header

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
        user = authenticate_with_api_key_or_current_user
        return error_unauthorized unless user
        return error_unauthorized if @user.suspended?

        true
      end

      def authorize_super_admin
        error_unauthorized unless @user.super_admin?
      end

      # Checks if the user is authenticated, sets @user to nil otherwise
      #
      # @return [User, NilClass]
      #
      # @see #pundit_user
      # @see #authenticate_with_api_key_or_current_user
      #
      # @note We could memoize the `@user ||=` but Rubocop wants to rename that to
      #       `authenticate_with_api_key_or_current_user` which would be bad as descendant classes
      #       have chosen to reference the `@user` instance variable.  Intsead [@jeremyf] is
      #       favoring leaving this method as is to reduce impact, and having `#pundit_user` do the
      #       memoization.
      #
      def authenticate_with_api_key_or_current_user
        @user = authenticate_with_api_key || current_user
      end

      # Checks if the user is authenticated, if not respond with an HTTP 401 Unauthorized
      #
      # @see #authenticate_with_api_key_or_current_user
      def authenticate_with_api_key_or_current_user!
        # [@jeremyf] Note, I'm not relying on the other method setting the instance variable, but
        # instead relying on the returned value.  This insulates us from an implementation detail
        # (namely should we use @user or current_user, which is a bit soupy in the API controller).
        user = authenticate_with_api_key_or_current_user
        error_unauthorized unless user
      end

      def add_deprecation_warning_header
        return if headers["Accept"].present? &&
          headers["Accept"].include?("application/vnd.forem.api-v#{@version}+json")

        # rubocop:disable Layout/LineLength
        response.headers["Warning"] = "299 - This endpoint is part of the V0 (beta) API. To start using the V1 endpoints add the `Accept` header and set it to `application/vnd.forem.api-v1+json`. Visit https://developers.forem.com/api for more information."
        # rubocop:enable Layout/LineLength
      end

      private

      # @note By default pundit_user is an alias of "#current_user".  However, as "#current_user"
      #       only tells part of the story, we need to roll our own.  That means checking if we have
      #       `@user` (which is set in #authenticate_with_api_key_or_current_user) but if that's not
      #       present, call the method.
      #
      # @return [User, NilClass]
      #
      # @note [@jeremyf] is choosing to reference the instance variable (e.g. `@user`) and if that's
      #       nil to call the `authenticate_with_api_key_or_current_user`.  This way I'm not
      #       altering the implementation details of the `authenticate_with_api_key_or_current_user`
      #       function by introducing memoization.
      #
      # @see #authenticate_with_api_key_or_current_user
      def pundit_user
        # What's going on here?
        @pundit_user ||= @user || authenticate_with_api_key_or_current_user
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
