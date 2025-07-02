# Included in ApplicationController for edge caching
module CachingHeaders
  extend ActiveSupport::Concern

  # The following is from the now deprecated fastly-rails gem
  # https://github.com/fastly/fastly-rails/tree/master/lib/fastly-rails/action_controller

  # Sets Cache-Control and Surrogate-Control HTTP headers
  # Surrogate-Control is stripped at the cache, Cache-Control persists (in case of other caches in front of fastly)
  # Defaults are:
  #  Cache-Control: 'public, no-cache'
  #  Surrogate-Control: 'max-age: 86400' - 1 day in seconds
  # custom config example:
  #  {cache_control: 'public, no-cache, maxage=xyz', surrogate_control: 'max-age: 100'}
  #
  # @note If you call this for a public Forem, you won't have access to data about the current user.
  #       You can check if they are authenticated but nothing else.
  #
  # @see {EdgeCacheSafetyCheck#current_user} for impact on "current_user"
  def set_cache_control_headers(
    max_age = ((ApplicationConfig["EDGE_CACHE_DURATION_IN_HOURS"] || 24).to_i).hours.to_i,
    surrogate_control: nil,
    stale_while_revalidate: nil,
    stale_if_error: 26_400
  )
    # Only public forems should be edge-cached based on current functionality.
    return unless Settings::UserExperience.public

    request.session_options[:skip] = true # no cookies

    RequestStore.store[:edge_caching_in_place] = true # To be observed downstream.

    response.headers["Cache-Control"] = "public, no-cache" # Used only by Fastly.
    response.headers["X-Accel-Expires"] = max_age.to_s # Used only by Nginx.
    response.headers["Surrogate-Control"] = surrogate_control.presence || build_surrogate_control(
      max_age, stale_while_revalidate: stale_while_revalidate, stale_if_error: stale_if_error
    )
  end

  def unset_cache_control_headers
    RequestStore.store[:edge_caching_in_place] = false
    response.headers["Cache-Control"] = nil
    response.headers["X-Accel-Expires"] = nil
    response.headers["Surrogate-Control"] = nil
  end

  # Sets Surrogate-Key HTTP header with one or more keys strips session data
  # from the request.
  def set_surrogate_key_header(*surrogate_keys)
    request.session_options[:skip] = true # No Set-Cookie
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  def add_vary_header(*vary_keys)
    existing = response.headers["Vary"]
    response.headers["Vary"] = [existing, *vary_keys].compact.join(", ")
  end

  private

  def build_surrogate_control(max_age, stale_while_revalidate: nil, stale_if_error: 26_400)
    surrogate_control = "max-age=#{max_age}"

    surrogate_control += ", stale-while-revalidate=#{stale_while_revalidate}" if stale_while_revalidate
    surrogate_control += ", stale-if-error=#{stale_if_error}" if stale_if_error
    surrogate_control
  end
end
