class OrganizationEmbedsController < ActionController::Metal
  include ActionController::Head
  include ActionController::Instrumentation

  SANDBOX_DIRECTIVE = "allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox".freeze
  PERMISSIONS_POLICY = %w[
    accelerometer=()
    autoplay=()
    camera=()
    clipboard-read=()
    display-capture=()
    geolocation=()
    gyroscope=()
    hid=()
    identity-credentials-get=()
    local-fonts=()
    magnetometer=()
    microphone=()
    midi=()
    otp-credentials=()
    payment=()
    publickey-credentials-create=()
    publickey-credentials-get=()
    serial=()
    storage-access=()
    usb=()
  ].join(", ").freeze
  SAFE_HOST_REGEXP = /\A[a-z0-9]+(?:[.-][a-z0-9]+)*(?::\d+)?\z/i
  SLUG_SUFFIX_REGEXP = /\A[a-z0-9\-]+\z/
  STALE_IF_ERROR_SECONDS = 26_400

  def show
    discard_session_and_cookies!
    apply_base_headers

    return render_plain_error(404, "Not Found") unless request.GET["mode"] == "embed"
    return render_plain_error(403, "Forbidden: embed only") if forbidden_fetch_destination?

    organization, page = resolve_embed_page
    return render_plain_error(404, "Not Found") unless page

    apply_embed_headers(organization, page)
    discard_session_and_cookies!
    self.status = 200
    self.content_type = "text/html; charset=utf-8"
    self.response_body = page.body_html.to_s
  end

  private

  def forbidden_fetch_destination?
    sec_fetch_dest = request.headers["Sec-Fetch-Dest"]
    sec_fetch_dest.present? && sec_fetch_dest != "iframe"
  end

  def resolve_embed_page
    org_slug = params[:org_slug].to_s.downcase
    suffix = params[:slug_suffix].to_s.downcase
    return [nil, nil] unless suffix.match?(SLUG_SUFFIX_REGEXP)

    organization = Organization.find_by_slug_or_legacy(org_slug) # rubocop:disable Rails/DynamicFindBy
    return [nil, nil] unless organization && FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])

    page = find_org_embed_page(organization, suffix)
    return [nil, nil] unless page && FeatureFlag.accessible?(page.feature_flag_name)

    [organization, page]
  end

  def find_org_embed_page(organization, suffix)
    slugs = [organization.slug, organization.old_slug, organization.old_old_slug]
      .compact_blank
      .uniq
      .map { |slug| "#{slug}/embed/#{suffix}" }
    organization.pages.embed_html.find_by(slug: slugs)
  end

  def apply_base_headers
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Permissions-Policy"] = PERMISSIONS_POLICY
    add_vary_header("Sec-Fetch-Dest")
  end

  def apply_embed_headers(organization, page)
    response.headers["Content-Security-Policy"] = [
      "sandbox #{SANDBOX_DIRECTIVE}",
      "frame-ancestors #{allowed_frame_ancestors(organization)}",
      "base-uri 'none'",
      "object-src 'none'",
    ].join("; ")
    response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
    apply_cache_headers(organization, page)
  end

  def apply_cache_headers(organization, page)
    unless Settings::UserExperience.public
      response.headers["Cache-Control"] = "private, no-store"
      return
    end

    max_age = (ApplicationConfig["EDGE_CACHE_DURATION_IN_HOURS"] || 24).to_i.hours.to_i
    surrogate_keys = ["show-page-#{page.slug}", organization.record_key]
      .filter_map { |key| key.to_s.delete("\r\n").strip.presence }
      .uniq
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
    response.headers["Cache-Control"] = "public, no-cache"
    response.headers["X-Accel-Expires"] = max_age.to_s
    response.headers["Surrogate-Control"] = "max-age=#{max_age}, stale-if-error=#{STALE_IF_ERROR_SECONDS}"
  end

  def allowed_frame_ancestors(organization)
    domains = (Subforem.cached_all_domains + [Settings::General.app_domain, organization.custom_domain])
      .compact_blank
      .uniq
      .select { |domain| domain.to_s.match?(SAFE_HOST_REGEXP) }
    origins = domains.map { |domain| "https://#{domain}" }
    origins.unshift("'self'") if Rails.env.local?
    origins.presence&.join(" ") || "'self'"
  end

  def add_vary_header(header_name)
    existing = response.headers["Vary"].to_s.split(",").map(&:strip).compact_blank
    response.headers["Vary"] = (existing | [header_name]).join(", ")
  end

  def discard_session_and_cookies!
    request.session_options[:skip] = true
    request.env.delete("action_dispatch.cookies")
    response.headers.delete("Set-Cookie")
  end

  def render_plain_error(status_code, message)
    response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox; frame-ancestors 'none'"
    response.headers["Cache-Control"] = "private, no-store"
    discard_session_and_cookies!
    self.status = status_code
    self.content_type = "text/plain; charset=utf-8"
    self.response_body = message
  end
end
