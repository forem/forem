# @note No pundit policy. All actions are unrestricted.
class AsyncInfoController < ApplicationController
  NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY = 15
  before_action :set_cache_control_headers, only: %i[navigation_links]

  # Debug endpoint to check user session state
  def debug_session_state
    if user_signed_in?
      render json: {
        user_id: current_user.id,
        current_sign_in_at: current_user.current_sign_in_at,
        last_sign_in_at: current_user.last_sign_in_at,
        remember_created_at: current_user.remember_created_at,
        remember_token_present: current_user.remember_token.present?,
        sign_in_count: current_user.sign_in_count
      }
    else
      render json: { error: "Not signed in" }, status: :unauthorized
    end
  end

  def base_data
    flash.discard(:notice)
    Rails.logger.info "[BASE_DATA] Request from #{request.host}, user_signed_in?=#{user_signed_in?}, request_id=#{request.request_id}"
    if user_signed_in?
      Rails.logger.info "[BASE_DATA] User #{current_user.id} DB STATE: current_sign_in_at=#{current_user.current_sign_in_at.inspect}, last_sign_in_at=#{current_user.last_sign_in_at.inspect}, remember_created_at=#{current_user.remember_created_at.inspect}, remember_token_present?=#{current_user.remember_token.present?}"
      session_valid = verify_state_of_user_session?
      Rails.logger.info "[BASE_DATA] verify_state_of_user_session? returned: #{session_valid}"
    end
    if user_signed_in? && verify_state_of_user_session?
      @user = current_user.decorate
      respond_to do |format|
        format.json do
          render json: {
            broadcast: broadcast_data,
            param: request_forgery_protection_token,
            token: form_authenticity_token,
            user: user_data,
            client_geolocation: client_geolocation,
            default_email_optin_allowed: default_email_optin_allowed?,
            creator: user_is_a_creator
          }
        end
      end
    else
      render json: {
        broadcast: broadcast_data,
        param: request_forgery_protection_token,
        token: form_authenticity_token
      }
    end
  end

  def broadcast_data
    return if ApplicationConfig["DISABLE_BROADCASTS"] == "yes"

    broadcast = Broadcast.announcement.active.first.presence
    return unless broadcast

    {
      title: broadcast&.title,
      html: broadcast&.processed_html,
      banner_class: helpers.banner_class(broadcast)
    }.to_json
  end

  # @note The `user_cache_key` uses `current_user` and this method assumes `@user` which is a
  #       decorated version of the user.  It would be nice if we were using the same "variable" for
  #       the cache key and for that which we cache.
  def user_data
    Rails.cache.fetch("#{current_user.cache_key_with_version}/user-info-#{RequestStore.store[:subforem_id]}",
                      expires_in: NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY.minutes) do
      AsyncInfo.to_hash(user: @user, context: self)
    end.to_json
  end

  def user_is_a_creator
    @user.creator?
  end

  def navigation_links
    # We're sending HTML over the wire hence 'render layout: false' enforces rails NOT TO look for a layout file to wrap
    # the view file - it allows us to not include the HTML headers for sending back to client.
    render layout: false
  end

  def verify_state_of_user_session?
    if current_user.last_sign_in_at.present? && current_user.current_sign_in_at.blank?
      Rails.logger.info "[VERIFY_SESSION] User #{current_user.id} found logged out (last_sign_in_at present, current_sign_in_at nil)"
      
      # Delete remember token cookie
      root_domain = Settings::General.app_domain
      cookies.delete(:remember_user_token, domain: ".#{root_domain}")
      cookies.delete(:remember_user_token)
      
      # Clear this domain's session completely
      reset_session
      
      return false
    end
    true
  end
end
