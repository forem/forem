class PageTag < LiquidTagBase
  PARTIAL = "liquids/page".freeze
  DEFAULT_HEIGHT = "600px".freeze
  LANDSCAPE_HEIGHT = "400px".freeze
  PORTRAIT_HEIGHT = "900px".freeze
  MIN_HEIGHT = 150
  MAX_HEIGHT = 2000
  FRAMELESS_OPTION = "frameless".freeze
  FRAMED_STYLE = "width: 100%; border: 1px solid var(--card-border, #e1e5e9); " \
                 "border-radius: var(--radius-auto, 6px); background: var(--card-bg, #fff);".freeze
  FRAMELESS_STYLE = "width: 100%; border: 0; display: block;".freeze
  ARTICLE_IFRAME_STYLE = "width: 100%; border: 0; display: block; background: var(--card-bg, #fff);".freeze
  HTML_TEMPLATES = %w[contained full_within_layout nav_bar_included].freeze
  RESERVED_FIRST_SEGMENTS = %w[p t events api admin rails sidekiq settings dashboard mod].freeze
  IFRAME_SANDBOX = OrganizationEmbedsController::SANDBOX_DIRECTIVE
  IFRAME_ALLOW_POLICY = [
    "camera 'none'",
    "microphone 'none'",
    "geolocation 'none'",
    "payment 'none'",
    "usb 'none'",
    "clipboard-read 'none'",
    "storage-access 'none'",
    "identity-credentials-get 'none'",
  ].join("; ").freeze

  STATIC_PAGE_SLUGS = {
    "/about" => { slug: "about", title: "About" },
    "/faq" => { slug: "faq", title: "FAQ" },
    "/terms" => { slug: "terms", title: "Terms of Use" },
    "/privacy" => { slug: "privacy", title: "Privacy Policy" },
    "/code-of-conduct" => { slug: "code-of-conduct", title: "Code of Conduct" },
    "/contact" => { slug: "contact", title: "Contact" },
    "/security" => { slug: "security", title: "Security" },
    "/community-moderation" => { slug: "community-moderation", title: "Community Moderation" },
    "/tag-moderation" => { slug: "tag-moderation", title: "Tag Moderation" },
    "/page/post-a-job" => { slug: "post-a-job", title: "Post a Job" },
    "/p/editor_guide" => { slug: nil, title: "Editor Guide" },
    "/p/publishing_from_rss_guide" => { slug: nil, title: "Publishing from RSS Guide" },
    "/p/markdown_basics" => { slug: nil, title: "Markdown Basics" }
  }.freeze

  def self.embeddable_page?(link)
    resolve_target(link, allow_bare_slug: false).present?
  end

  def self.resolve_target(raw_input, allow_bare_slug: false)
    token = raw_input.to_s.strip
    return if token.blank?

    if token.match?(%r{\Ahttps?://}i)
      resolve_full_url(token)
    elsif token.start_with?("/") && !token.start_with?("//")
      resolve_relative_input(token)
    elsif allow_bare_slug
      resolve_bare_slug(token)
    end
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def self.build_attribution(target)
    owner = target[:owner]
    case owner
    when User
      {
        owner_type: "user",
        owner_name: owner.name,
        owner_path: owner.path,
        owner_avatar_url: owner.profile_image_90,
        canonical_url: nil
      }
    when Organization
      {
        owner_type: "organization",
        owner_name: owner.name,
        owner_path: owner.path,
        owner_avatar_url: owner.profile_image_90,
        canonical_url: target[:sandboxed] ? nil : target[:base_url]
      }
    else
      {
        owner_type: "site",
        owner_name: Settings::Community.community_name.presence || "Forem",
        owner_path: "/",
        owner_avatar_url: site_logo_url,
        canonical_url: target[:sandboxed] ? nil : target[:base_url]
      }
    end
  end

  def self.site_logo_url
    Settings::General.resized_logo.presence ||
      Settings::General.original_logo.presence ||
      Settings::General.logo_png.presence
  end
  private_class_method :site_logo_url

  def self.resolve_full_url(token)
    uri = Addressable::URI.parse(token)
    return unless uri.host.present? && local_domain?(uri)

    subforem_id = resolve_subforem_id(uri.host)
    port_suffix = uri.port ? ":#{uri.port}" : ""
    origin_base = "#{uri.scheme}://#{uri.host}#{port_suffix}"
    resolve_path(
      uri.path,
      subforem_id: subforem_id,
      origin_base: origin_base,
      query: uri.query,
      fragment: uri.fragment,
    )
  end
  private_class_method :resolve_full_url

  def self.resolve_relative_input(token)
    uri = Addressable::URI.parse(token)
    resolve_path(
      uri.path,
      subforem_id: RequestStore.store[:subforem_id],
      origin_base: nil,
      query: uri.query,
      fragment: uri.fragment,
    )
  end
  private_class_method :resolve_relative_input

  def self.resolve_bare_slug(token)
    return if token.include?("://")

    uri = Addressable::URI.parse("/#{token.delete_prefix('/')}")
    subforem_id = RequestStore.store[:subforem_id]
    resolve_path(uri.path, subforem_id: subforem_id, origin_base: nil, query: uri.query, fragment: uri.fragment) ||
      resolve_path(
        "/page#{uri.path}",
        subforem_id: subforem_id,
        origin_base: nil,
        query: uri.query,
        fragment: uri.fragment,
      )
  end
  private_class_method :resolve_bare_slug

  def self.local_domain?(uri)
    host = uri.host.to_s.downcase
    host_with_port = uri.port ? "#{host}:#{uri.port}" : host
    base_uri = Addressable::URI.parse(URL.url)
    url_hosts = [base_uri.host, (base_uri.port ? "#{base_uri.host}:#{base_uri.port}" : nil)]
    allowed = (Subforem.cached_domains + [Settings::General.app_domain, URL.domain] + url_hosts)
      .compact_blank
      .map(&:downcase)

    allowed.include?(host) || allowed.include?(host_with_port)
  end
  private_class_method :local_domain?

  def self.resolve_subforem_id(host)
    return RequestStore.store[:subforem_id] if Subforem.disabled_by_env?

    Subforem.cached_id_by_domain(host.to_s.downcase) || RequestStore.store[:subforem_id]
  end
  private_class_method :resolve_subforem_id

  def self.resolve_path(raw_path, subforem_id:, origin_base:, query:, fragment:)
    segments = normalized_segments(raw_path)
    return if segments.nil?

    normalized_path = "/#{segments.join('/')}"
    target = resolve_static_page(normalized_path, subforem_id) ||
      resolve_prefixed_page(segments, normalized_path, subforem_id) ||
      resolve_top_level_or_nested_page(segments, subforem_id)
    return unless target

    base = build_page_url(target[:path], page: target[:page], origin_base: origin_base)
    {
      url: append_embed_params(base, query: query, fragment: fragment),
      base_url: base,
      path: target[:path],
      title: target[:title],
      page: target[:page],
      owner: target[:owner],
      sandboxed: target[:sandboxed] == true
    }
  end
  private_class_method :resolve_path

  def self.normalized_segments(raw_path)
    return if raw_path.blank?

    segments = raw_path.split("/").compact_blank
    return if segments.empty? || segments.size > Page::PAGE_DIRECTORY_LIMIT
    return if segments.last.match?(/\.(?:txt|json|css|xml)\z/i)

    segments
  end
  private_class_method :normalized_segments

  def self.resolve_static_page(normalized_path, subforem_id)
    info = STATIC_PAGE_SLUGS[normalized_path]
    return unless info

    page = info[:slug] ? find_scoped_page(info[:slug], subforem_id) : nil
    return if page && !embeddable_record?(page)

    { path: normalized_path, title: page&.title || info[:title], page: page }
  end
  private_class_method :resolve_static_page

  def self.resolve_prefixed_page(segments, normalized_path, subforem_id)
    if segments.size == 2 && segments[0] == "page"
      page = find_scoped_page(segments[1], subforem_id)
      return unless embeddable_standalone_page?(page)

      { path: page.path, title: page.title, page: page, sandboxed: false }
    elsif segments.size == 3 && segments[1] == "p"
      resolve_organization_page(segments[0], segments[2], normalized_path)
    elsif segments.size == 3 && segments[1] == "embed"
      resolve_owner_embed_page(segments[0], segments[2])
    end
  end
  private_class_method :resolve_prefixed_page

  def self.resolve_organization_page(org_slug, page_suffix, normalized_path)
    org = Organization.find_by(slug: org_slug)
    return unless org && FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[org])

    org_page = org.pages.non_embed_html.find_by(slug: "#{org.slug}/#{page_suffix}")
    return unless org_page && embeddable_record?(org_page)

    { path: normalized_path, title: org_page.title, page: org_page, owner: org, sandboxed: false }
  end
  private_class_method :resolve_organization_page

  def self.resolve_owner_embed_page(owner_slug, page_suffix)
    normalized_owner = owner_slug.to_s.downcase
    normalized_suffix = page_suffix.to_s.downcase
    return unless normalized_suffix.match?(OrganizationEmbedsController::SLUG_SUFFIX_REGEXP)

    owner = resolve_embed_owner(normalized_owner)
    return unless owner && embed_owner_allowed?(owner)

    embed_page = find_owner_embed_page(owner, normalized_suffix)
    return unless embed_page && embeddable_html_record?(embed_page)

    {
      path: "/#{owner.username}/embed/#{normalized_suffix}",
      title: embed_page.title,
      page: embed_page,
      owner: owner,
      sandboxed: true
    }
  end
  private_class_method :resolve_owner_embed_page

  def self.resolve_embed_owner(slug)
    Organization.find_by(slug: slug) ||
      User.find_by(username: slug) ||
      Organization.find_by(old_slug: slug) ||
      Organization.find_by(old_old_slug: slug) ||
      User.for_legacy_username(slug)
  end
  private_class_method :resolve_embed_owner

  def self.embed_owner_allowed?(owner)
    case owner
    when Organization
      FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[owner])
    when User
      owner.can_serve_embed_pages?
    else
      false
    end
  end
  private_class_method :embed_owner_allowed?

  def self.find_owner_embed_page(owner, normalized_suffix)
    current_page = owner.pages.embed_html.find_by(slug: "#{owner.username}/embed/#{normalized_suffix}")
    return current_page if current_page

    legacy_slugs = [owner.old_username, owner.old_old_username]
      .compact_blank
      .uniq
      .map { |slug| "#{slug}/embed/#{normalized_suffix}" }
    legacy_page = owner.pages.embed_html.find_by(slug: legacy_slugs) if legacy_slugs.any?
    return legacy_page if legacy_page

    escaped_suffix = ActiveRecord::Base.sanitize_sql_like(normalized_suffix)
    owner.pages.embed_html.where("slug LIKE ?", "%/embed/#{escaped_suffix}").order(id: :desc).detect do |page|
      page.slug.end_with?("/embed/#{normalized_suffix}") && page.slug.count("/") == 2
    end
  end
  private_class_method :find_owner_embed_page

  def self.embeddable_html_record?(page)
    Settings::UserExperience.public &&
      page.embed_html? &&
      page.redirect_to_url.blank? &&
      FeatureFlag.accessible?(page.feature_flag_name)
  end
  private_class_method :embeddable_html_record?

  def self.resolve_top_level_or_nested_page(segments, subforem_id)
    return if RESERVED_FIRST_SEGMENTS.include?(segments[0]) || %w[comment embed].include?(segments[1])

    case segments.size
    when 1 then resolve_single_segment_page(segments[0], subforem_id)
    when 2 then resolve_two_segment_page(segments[0], segments[1], subforem_id)
    else resolve_multi_segment_page(segments, subforem_id)
    end
  end
  private_class_method :resolve_top_level_or_nested_page

  def self.resolve_single_segment_page(segment, subforem_id)
    page = find_scoped_page(segment, subforem_id, top_level_only: true)
    return unless embeddable_standalone_page?(page) && !shadowed_single_segment?(segment)

    { path: page.path, title: page.title, page: page }
  end
  private_class_method :resolve_single_segment_page

  def self.resolve_two_segment_page(first_segment, second_segment, subforem_id)
    page = find_scoped_page("#{first_segment}/#{second_segment}", subforem_id, top_level_only: true)
    return unless embeddable_standalone_page?(page) && !shadowed_two_segment?(first_segment, second_segment)

    { path: page.path, title: page.title, page: page }
  end
  private_class_method :resolve_two_segment_page

  def self.resolve_multi_segment_page(segments, subforem_id)
    slug = segments.join("/")
    page = find_scoped_page(slug, subforem_id)
    return unless embeddable_standalone_page?(page)

    { path: "/#{slug}", title: page.title, page: page }
  end
  private_class_method :resolve_multi_segment_page

  def self.find_scoped_page(slug, subforem_id, top_level_only: false)
    criteria = { slug: slug }
    criteria[:is_top_level_path] = true if top_level_only

    subforem_scope = Page.from_subforem(subforem_id)
    return Page.find_by(criteria) if subforem_scope.where_clause.empty?

    subforem_scope.find_by(criteria) || Page.find_by(criteria)
  end
  private_class_method :find_scoped_page

  def self.embeddable_standalone_page?(page)
    page.present? && page.organization_id.nil? && page.user_id.nil? && embeddable_record?(page)
  end
  private_class_method :embeddable_standalone_page?

  def self.embeddable_record?(page)
    HTML_TEMPLATES.include?(page.template) &&
      page.redirect_to_url.blank? &&
      FeatureFlag.accessible?(page.feature_flag_name)
  end
  private_class_method :embeddable_record?

  def self.shadowed_single_segment?(segment)
    User.exists?(username: segment) ||
      Organization.exists?(slug: segment)
  end
  private_class_method :shadowed_single_segment?

  def self.shadowed_two_segment?(first_segment, second_segment)
    Article.exists?(path: "/#{first_segment.downcase}/#{second_segment}") ||
      Article.exists?(slug: second_segment) ||
      Podcast.available.exists?(slug: first_segment)
  end
  private_class_method :shadowed_two_segment?

  def self.build_page_url(path, page:, origin_base:)
    if page&.organization_id.nil? && page&.user_id.nil? && page&.subforem_id.present? && !Subforem.disabled_by_env?
      domain = Subforem.cached_id_to_domain_hash[page.subforem_id]
      URL.url(path, domain)
    elsif origin_base.present?
      "#{origin_base}#{path}"
    else
      subforem_id = Subforem.disabled_by_env? ? nil : RequestStore.store[:subforem_id]
      domain = subforem_id ? Subforem.cached_id_to_domain_hash[subforem_id] : nil
      URL.url(path, domain)
    end
  end
  private_class_method :build_page_url

  def self.append_embed_params(base_url, query:, fragment:)
    uri = Addressable::URI.parse(base_url)
    uri.query_values = (uri.query_values || {}).merge(parse_query_params(query)).merge("mode" => "embed")
    uri.fragment = fragment if fragment.present?
    uri.to_s
  end
  private_class_method :append_embed_params

  def self.parse_query_params(query)
    return {} if query.blank?

    Addressable::URI.form_unencode(query).to_h
  rescue StandardError
    {}
  end
  private_class_method :parse_query_params

  def initialize(_tag_name, input, parse_context)
    super
    cleaned = CGI.unescape_html(strip_tags(input.to_s)).strip
    args = cleaned.split(/\s+/)
    target = self.class.resolve_target(args[0], allow_bare_slug: true)
    raise StandardError, I18n.t("liquid_tags.page_tag.invalid_page") unless target

    @url = target[:url]
    @title = target[:title]
    @sandboxed = target[:sandboxed] == true
    @in_article = parse_context.partial_options[:source].is_a?(Article)
    @attribution = @in_article ? self.class.build_attribution(target) : nil
    options = args.drop(1)
    @frameless = options.any? { |option| option.casecmp?(FRAMELESS_OPTION) }
    @height = parse_height(options.detect { |option| !option.casecmp?(FRAMELESS_OPTION) })
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url,
        title: @title,
        height: @height,
        sandboxed: @sandboxed,
        in_article: @in_article,
        frameless: @frameless,
        attribution: @attribution,
        style: iframe_style
      },
    )
  end

  private

  def iframe_style
    return ARTICLE_IFRAME_STYLE if @in_article

    @frameless ? FRAMELESS_STYLE : FRAMED_STYLE
  end

  def parse_height(option)
    return DEFAULT_HEIGHT if option.blank?

    normalized = option.strip.downcase
    case normalized
    when "landscape"
      LANDSCAPE_HEIGHT
    when "portrait"
      PORTRAIT_HEIGHT
    when /\A(?:height=)?(\d+)(?:px)?\z/
      "#{Regexp.last_match(1).to_i.clamp(MIN_HEIGHT, MAX_HEIGHT)}px"
    else
      DEFAULT_HEIGHT
    end
  end
end

Liquid::Template.register_tag("page", PageTag)
