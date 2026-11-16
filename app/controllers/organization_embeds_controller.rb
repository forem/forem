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

    return render_plain_error(404, "Not Found") unless Settings::UserExperience.public
    return render_plain_error(404, "Not Found") unless request.GET["mode"] == "embed"
    return render_plain_error(403, "Forbidden: embed only") if forbidden_fetch_destination?

    owner, page = resolve_embed_page
    return render_plain_error(404, "Not Found") unless page

    apply_embed_headers(owner, page)
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
    owner_slug = params[:org_slug].to_s.downcase
    suffix = params[:slug_suffix].to_s.downcase
    return [nil, nil] unless suffix.match?(SLUG_SUFFIX_REGEXP)

    owner = resolve_embed_owner(owner_slug)
    return [nil, nil] unless owner && owner_embed_allowed?(owner)

    page = find_owner_embed_page(owner, suffix)
    return [nil, nil] unless page && FeatureFlag.accessible?(page.feature_flag_name)

    [owner, page]
  end

  def resolve_embed_owner(slug)
    Organization.find_by(slug: slug) ||
      User.find_by(username: slug) ||
      Organization.find_by(old_slug: slug) ||
      Organization.find_by(old_old_slug: slug) ||
      User.for_legacy_username(slug)
  end

  def owner_embed_allowed?(owner)
    case owner
    when Organization
      FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[owner])
    when User
      owner.can_serve_embed_pages?
    else
      false
    end
  end

  def find_owner_embed_page(owner, suffix)
    current_page = owner.pages.embed_html.find_by(slug: "#{owner.username}/embed/#{suffix}")
    return current_page if current_page

    legacy_slugs = [owner.old_username, owner.old_old_username]
      .compact_blank
      .uniq
      .map { |slug| "#{slug}/embed/#{suffix}" }
    legacy_page = owner.pages.embed_html.find_by(slug: legacy_slugs) if legacy_slugs.any?
    return legacy_page if legacy_page

    escaped_suffix = ActiveRecord::Base.sanitize_sql_like(suffix)
    owner.pages.embed_html.where("slug LIKE ?", "%/embed/#{escaped_suffix}").order(id: :desc).detect do |page|
      page.slug.end_with?("/embed/#{suffix}") && page.slug.count("/") == 2
    end
  end

  def apply_base_headers
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Permissions-Policy"] = PERMISSIONS_POLICY
    add_vary_header("Sec-Fetch-Dest")
  end

  def apply_embed_headers(owner, page)
    response.headers["Content-Security-Policy"] = [
      "sandbox #{SANDBOX_DIRECTIVE}",
      "frame-ancestors #{allowed_frame_ancestors(owner)}",
      "base-uri 'none'",
      "object-src 'none'",
    ].join("; ")
    response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
    apply_cache_headers(owner, page)
  end

  def apply_cache_headers(owner, page)
    max_age = (ApplicationConfig["EDGE_CACHE_DURATION_IN_HOURS"] || 24).to_i.hours.to_i
    owner_keys = [owner.record_key]
    owner_keys << owner.profile_identity_record_key if owner.is_a?(User)
    surrogate_keys = (["show-page-#{page.slug}"] + owner_keys)
      .filter_map { |key| key.to_s.delete("\r\n").strip.presence }
      .uniq
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
    response.headers["Cache-Control"] = "public, no-cache"
    response.headers["X-Accel-Expires"] = max_age.to_s
    response.headers["Surrogate-Control"] = "max-age=#{max_age}, stale-if-error=#{STALE_IF_ERROR_SECONDS}"
  end

  def allowed_frame_ancestors(owner)
    custom_domain = owner.respond_to?(:custom_domain) ? owner.custom_domain : nil
    domains = (Subforem.cached_all_domains + [Settings::General.app_domain, custom_domain])
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
