class Api::V0::ApiController < ApplicationController
  def cors_set_access_control_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, Token"
    headers["Access-Control-Max-Age"] = "1728000"
  end

  def cors_preflight_check
    return unless request.method == "OPTIONS"

    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-Prototype-Version, Token"
    headers["Access-Control-Max-Age"] = "1728000"

    render text: "", content_type: "text/plain"
  end

  rescue_from ActionController::ParameterMissing do |exc|
    error_unprocessable_entity(exc.message)
  end

  rescue_from ActiveRecord::RecordInvalid do |exc|
    error_unprocessable_entity(exc.message)
  end

  rescue_from ActiveRecord::RecordNotFound do |_exc|
    error_not_found
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

  def authenticate_with_api_key_or_current_user
    if request.headers["api-key"]
      authenticate_with_api_key
    else
      @user = current_user
    end
  end

  def authenticate_with_api_key
    api_key = request.headers["api-key"]
    return error_unauthorized unless api_key

    api_secret = ApiSecret.includes(:user).find_by(secret: api_key)
    return error_unauthorized unless api_secret

    # guard against timing attacks
    # see <https://www.slideshare.net/NickMalcolm/timing-attacks-and-ruby-on-rails>
    if ActiveSupport::SecurityUtils.secure_compare(api_secret.secret, api_key)
      @user = api_secret.user
    else
      error_unauthorized
    end
  end
end
