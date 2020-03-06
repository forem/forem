class Api::V0::ApiController < ApplicationController
  protect_from_forgery with: :exception, prepend: true

  include ValidRequest

  respond_to :json

  rescue_from ActionController::ParameterMissing do |exc|
    error_unprocessable_entity(exc.message)
  end

  rescue_from ActiveRecord::RecordInvalid do |exc|
    error_unprocessable_entity(exc.message)
  end

  rescue_from ActiveRecord::RecordNotFound do |_exc|
    error_not_found
  end

  rescue_from Pundit::NotAuthorizedError do |_exc|
    error_unauthorized
  end

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
    if doorkeeper_token
      @user = User.find(doorkeeper_token.resource_owner_id)
      return error_unauthorized unless @user
    elsif request.headers["api-key"]
      @user = authenticate_with_api_key
      return error_unauthorized unless @user
    elsif current_user
      @user = current_user
    else
      error_unauthorized
    end
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
    return nil unless api_key

    api_secret = ApiSecret.includes(:user).find_by(secret: api_key)
    return nil unless api_secret

    # guard against timing attacks
    # see <https://www.slideshare.net/NickMalcolm/timing-attacks-and-ruby-on-rails>
    secure_secret = ActiveSupport::SecurityUtils.secure_compare(api_secret.secret, api_key)
    return api_secret.user if secure_secret
  end
end
