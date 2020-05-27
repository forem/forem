module FastlyHeaders
  extend ActiveSupport::Concern

  # The following is from the now deprecated fastly-rails gem
  # https://github.com/fastly/fastly-rails/tree/master/lib/fastly-rails/action_controller

  # Sets Cache-Control and Surrogate-Control HTTP headers
  # Surrogate-Control is stripped at the cache, Cache-Control persists (in case of other caches in front of fastly)
  # Defaults are:
  #  Cache-Control: 'public, no-cache'
  #  Surrogate-Control: 'max-age: 86400' - 30 days in seconds
  # custom config example:
  #  {cache_control: 'public, no-cache, maxage=xyz', surrogate_control: 'max-age: 100'}
  def set_cache_control_headers(max_age = 1.day.to_i, opts = {})
    request.session_options[:skip] = true # no cookies
    response.headers["Cache-Control"] = opts[:cache_control] || "public, no-cache"
    response.headers["Surrogate-Control"] = opts[:surrogate_control] || build_surrogate_control(max_age, opts)
  end

  # Sets Surrogate-Key HTTP header with one or more keys strips session data
  # from the request
  def set_surrogate_key_header(*surrogate_keys)
    request.session_options[:skip] = true # No Set-Cookie
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  private

  def build_surrogate_control(max_age, opts)
    surrogate_control = "max-age=#{max_age}"
    stale_while_revalidate = opts[:stale_while_revalidate]
    stale_if_error = opts[:stale_if_error] || 26_400

    surrogate_control += ", stale-while-revalidate=#{stale_while_revalidate}" if stale_while_revalidate
    surrogate_control += ", stale-if-error=#{stale_if_error}" if stale_if_error
    surrogate_control
  end
end
