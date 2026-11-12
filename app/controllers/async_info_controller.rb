# @note No pundit policy. All actions are unrestricted.
class AsyncInfoController < ApplicationController
  NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY = 15
  before_action :set_cache_control_headers, only: %i[navigation_links]
  skip_before_action :verify_private_forem,
                     :forward_to_app_config_domain,
                     :redirect_custom_domain_non_profile_pages,
                     :determine_locale,
                     :set_request_signed_in_context,
                     only: %i[base_data]

  def base_data
    had_session_user = session_current_user_id.present?
    skip_session = can_skip_base_data_session_commit?
    RequestStore.store[:custom_domain_org] = request.env["forem.custom_domain_org"]

    if authenticated_for_base_data?
      RequestStore.store[:user_signed_in] = true
      current_user.update_presence!
      @user = current_user.decorate
      request.session_options[:skip] = true if skip_session && had_session_user
      render_authenticated_base_data(fast_form_authenticity_token)
    else
      RequestStore.store[:user_signed_in] = false
      request.session_options[:skip] = true if skip_session && !had_session_user
      render_anonymous_base_data(fast_form_authenticity_token)
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
    cache_key = "#{current_user.cache_key_with_version}/user-info-json-#{RequestStore.store[:subforem_id]}"
    cached = Rails.cache.fetch(cache_key, expires_in: NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY.minutes) do
      AsyncInfo.to_hash(user: @user, context: self).to_json
    end
    cached.is_a?(String) ? cached : cached.to_json
  end

  def user_is_a_creator
    if current_user.instance_of?(User)
      return false unless current_user.cached_role_names.include?("creator")
      return true if @user.creator?

      Rails.cache.delete("user-#{current_user.id}/role_names")
      return false
    end

    @user.creator?
  end

  def navigation_links
    subforem_id = RequestStore.store[:subforem_id]
    set_surrogate_key_header("navigation_links", ("navigation_links-#{subforem_id}" if subforem_id.present?))
    # We're sending HTML over the wire hence 'render layout: false' enforces rails NOT TO look for a layout file to wrap
    # the view file - it allows us to not include the HTML headers for sending back to client.
    render layout: false
  end

  def verify_state_of_user_session?
    return true unless current_user.last_sign_in_at.present? && current_user.current_sign_in_at.blank?

    sign_out(current_user)
    false
  end

  private

  def can_skip_base_data_session_commit?
    had_csrf_token = session[:_csrf_token].present?
    had_flash_notice = session.key?("flash") && flash[:notice].present?
    flash.discard(:notice) if had_flash_notice
    had_csrf_token && !had_flash_notice
  end

  def authenticated_for_base_data?
    (session_current_user_id || cookies[:remember_user_token].present?) &&
      user_signed_in? && verify_state_of_user_session?
  end

  def render_authenticated_base_data(token_str)
    bcast = broadcast_data
    u_data = user_data
    geo = client_geolocation
    optin = default_email_optin_allowed?
    is_creator = user_is_a_creator

    respond_to do |format|
      format.json do
        native_json = ForemNative.build_base_data_json(
          broadcast: bcast,
          param: request_forgery_protection_token.to_s,
          token: token_str,
          user: u_data,
          client_geolocation: geo,
          default_email_optin_allowed: optin,
          creator: is_creator,
        )
        render json: native_json || {
          broadcast: bcast,
          param: request_forgery_protection_token,
          token: token_str,
          user: u_data,
          client_geolocation: geo,
          default_email_optin_allowed: optin,
          creator: is_creator
        }
      end
    end
  end

  def render_anonymous_base_data(token_str)
    bcast = broadcast_data
    native_json = ForemNative.build_base_data_json(
      broadcast: bcast,
      param: request_forgery_protection_token.to_s,
      token: token_str,
    )
    render json: native_json || {
      broadcast: bcast,
      param: request_forgery_protection_token,
      token: token_str
    }
  end

  def fast_form_authenticity_token
    return form_authenticity_token if per_form_csrf_tokens

    encoded_real = request.env[CSRF_TOKEN] ||= csrf_token_storage_strategy.fetch(request) || generate_csrf_token
    if encoded_real.instance_of?(String)
      masked = ForemNative.mask_authenticity_token(
        encoded_real,
        SecureRandom.random_bytes(AUTHENTICITY_TOKEN_LENGTH),
      )
      return masked if masked
    end

    form_authenticity_token
  end
end
