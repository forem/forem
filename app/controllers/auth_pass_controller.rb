class AuthPassController < ApplicationController
  # Skip CSRF protection for this action
  skip_before_action :verify_authenticity_token, only: [:iframe, :token_login]

  def iframe
    if user_signed_in?
      @token = generate_auth_token(current_user)
    end

    # Set the appropriate Content Security Policy (CSP) headers if necessary
    response.headers['X-Frame-Options'] = 'ALLOWALL'

    render layout: false
  end

  def token_login
    token = params[:token]
    payload = decode_auth_token(token)

    if payload && payload['user_id']
      user = User.find_by(id: payload['user_id'])
      if user
        sign_in(user)
        render json: { success: true }
      else
        render json: { success: false, error: 'User not found' }, status: :unauthorized
      end
    else
      render json: { success: false, error: 'Invalid token' }, status: :unauthorized
    end
  end

  private

  def generate_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.from_now.to_i, # Token expires in 5 minutes
    }
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def decode_auth_token(token)
    JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
  rescue JWT::ExpiredSignature
    nil
  rescue
    nil
  end
end