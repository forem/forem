class LiquidEmbedExtractor
  # We implemented a non-rendering parser scanning body_markdown directly to avoid instantiating Liquid tags.
  # This prevents background sync jobs from invoking Pundit auth, HTTP network requests (like UnifiedEmbed fetching
  # OpenGraph data), or halting the extraction entirely if a single tag fails Liquid::Template context validations.
  LIQUID_TAG_REGEX = /\{%\s*([a-zA-Z0-9_]+)\s+(.*?)\s*%\}/
  COMMENT_PATH_REGEX = %r{\A/[^/]+/comment/(?<comment_id>\w+)/?\z}
  COMMENT_ID_REGEX = /\A(?<comment_id>\w+)\z/
  FEED_OPTION_REGEX = /\A(org|tag|tags)=(\S+)\z/
  SIMPLE_KIND_TYPES = {
    user: "User",
    comment: "Comment",
    tag: "Tag",
    podcast: "Podcast",
    organization: "Organization"
  }.freeze

  def self.extract(record)
    text = extract_markdown(record)
    return [] if text.blank?

    raw_tags = ForemNative.extract_liquid_embed_tags(text) || legacy_extract_tags(text)
    return [] if raw_tags.empty?

    resolve_references(raw_tags)
  end

  def self.extract_markdown(record)
    if defined?(Billboard) && record.is_a?(Billboard)
      return "" unless record.forem_markdown?

      [record.body_markdown, record.minimized_body_markdown].compact_blank.join("\n")
    elsif defined?(Page) && record.is_a?(Page) && record.uses_page_template?
      extract_page_template_markdown(record)
    elsif record.respond_to?(:body_markdown)
      record.body_markdown.to_s
    else
      ""
    end
  end
  private_class_method :extract_markdown

  def self.extract_page_template_markdown(page)
    template = page.page_template
    return "" if template&.body_markdown.blank?

    rendered = template.body_markdown.dup
    data = page.template_data || {}
    template.schema_fields.each do |field|
      field_name = field["name"]
      rendered.gsub!("{{#{field_name}}}", data[field_name].to_s) if field_name.present?
    end
    rendered
  end
  private_class_method :extract_page_template_markdown

  def self.legacy_extract_tags(text)
    # Strip codeblocks to reliably extract active tags only natively
    stripped_content = text.gsub(/```.*?```/m, "").gsub(/`.*?`/, "")

    tags = stripped_content.scan(LIQUID_TAG_REGEX).map do |match|
      tag_name = match[0].downcase
      options = match[1].strip
      url = options.split.first || options
      [tag_name, url, options]
    end
    tags.uniq
  end

  def self.resolve_references(raw_tags)
    expanded_tags = expand_raw_tags(raw_tags)
    lookups = build_reference_lookups(expanded_tags)

    expanded_tags.map do |entry|
      ref_type, ref_id = lookup_reference(entry, lookups)
      {
        tag_name: entry[:tag_name],
        url: entry[:url],
        options: entry[:options],
        referenced_type: ref_type,
        referenced_id: ref_id
      }
    end.uniq
  end
  private_class_method :resolve_references

  def self.expand_raw_tags(raw_tags)
    domains = internal_domains
    entries = []

    raw_tags.each do |tag_name, url, options|
      if tag_name == "feed"
        entries.concat(expand_feed_entries(url, options))
      else
        entries << build_tag_entry(tag_name, url, options, domains)
      end
    end

    entries
  end
  private_class_method :expand_raw_tags

  def self.expand_feed_entries(url, options)
    org_slug, tag_names = parse_feed_sources(options)

    if org_slug.present?
      [{
        tag_name: "feed",
        url: org_slug,
        options: options,
        kind: :organization,
        key: org_slug.downcase
      }]
    elsif tag_names.any?
      tag_names.map do |tag_name|
        normalized_tag = tag_name.downcase
        {
          tag_name: "feed",
          url: normalized_tag,
          options: options,
          kind: :tag,
          key: normalized_tag
        }
      end
    else
      [{ tag_name: "feed", url: url, options: options, kind: :none, key: nil }]
    end
  end
  private_class_method :expand_feed_entries

  def self.parse_feed_sources(options)
    org_slug = nil
    tag_names = []

    options.to_s.split.each do |token|
      match = token.match(FEED_OPTION_REGEX)
      next unless match

      case match[1]
      when "org"
        org_slug = match[2]
      when "tag"
        tag_names = [match[2]]
      when "tags"
        parsed = match[2].split(",").map(&:strip).compact_blank
        tag_names = parsed if parsed.any?
      end
    end

    [org_slug, tag_names.uniq]
  end

  def self.build_tag_entry(tag_name, url, options, domains)
    case tag_name
    when "user"
      simple_entry(tag_name, url, options, :user, extract_single_segment_identifier(url, domains)&.downcase)
    when "comment", "devcomment"
      simple_entry(tag_name, url, options, :comment, extract_comment_id_code(url, domains))
    when "tag"
      simple_entry(tag_name, url, options, :tag, extract_tag_identifier(url, domains)&.downcase)
    when "podcast"
      simple_entry(tag_name, url, options, :podcast, url&.strip&.downcase)
    when "organization", "org", "org_posts"
      simple_entry(tag_name, url, options, :organization, extract_single_segment_identifier(url, domains)&.downcase)
    when "link", "post"
      build_link_entry(tag_name, url, options, domains)
    when "embed"
      build_embed_entry(tag_name, url, options, domains)
    else
      simple_entry(tag_name, url, options, :none, nil)
    end
  end
  private_class_method :build_tag_entry

  def self.simple_entry(tag_name, url, options, kind, key)
    { tag_name: tag_name, url: url, options: options, kind: kind, key: key }
  end
  private_class_method :simple_entry

  def self.build_link_entry(tag_name, url, options, domains)
    target = options.to_s.strip.split.first || url
    pair = extract_internal_owner_and_slug(target, domains, allow_relative: true)
    simple_entry(tag_name, url, options, pair ? :article : :none, pair)
  end
  private_class_method :build_link_entry

  def self.build_embed_entry(tag_name, url, options, domains)
    embed_url = extract_embed_url(url, options)
    normalized_url = url == "minimal" && embed_url.present? ? embed_url : url
    kind, key = classify_internal_embed(embed_url, domains)
    simple_entry(tag_name, normalized_url, options, kind, key)
  end
  private_class_method :build_embed_entry

  def self.build_reference_lookups(entries)
    buckets = Hash.new { |h, k| h[k] = [] }
    entries.each do |entry|
      next if entry[:kind] == :none || entry[:key].blank?

      case entry[:kind]
      when :article_or_podcast
        buckets[:article] << entry[:key]
        buckets[:podcast] << entry[:key].first
      when :user_or_organization
        buckets[:user] << entry[:key]
        buckets[:organization] << entry[:key]
      else
        buckets[entry[:kind]] << entry[:key]
      end
    end

    org_lookup = batch_organization_lookup(buckets[:organization])
    user_lookup = batch_pluck_downcase(User, :username, buckets[:user])
    {
      user: user_lookup,
      comment: batch_pluck(Comment, :id_code, buckets[:comment]),
      tag: batch_pluck_downcase(Tag, :name, buckets[:tag]),
      podcast: batch_pluck_downcase(Podcast, :slug, buckets[:podcast]),
      organization: org_lookup,
      article: batch_article_lookup(buckets[:article], user_lookup, org_lookup)
    }
  end
  private_class_method :build_reference_lookups

  def self.batch_pluck(model, column, values)
    return if values.empty?

    model.where(column => values.uniq).pluck(column, :id).to_h
  end
  private_class_method :batch_pluck

  def self.batch_pluck_downcase(model, column, values)
    return if values.empty?

    model.where(column => values.uniq).pluck(column, :id).to_h.transform_keys { |k| k.to_s.downcase }
  end
  private_class_method :batch_pluck_downcase

  def self.batch_organization_lookup(slugs)
    return if slugs.empty?

    unique_slugs = slugs.uniq
    rows = Organization
      .where(slug: unique_slugs)
      .or(Organization.where(old_slug: unique_slugs))
      .or(Organization.where(old_old_slug: unique_slugs))
      .pluck(:id, :slug, :old_slug, :old_old_slug)

    map = {}
    [1, 2, 3].each do |col_idx|
      rows.each do |row|
        candidate = row[col_idx]
        map[candidate.downcase] ||= row[0] if candidate.present?
      end
    end
    map
  end
  private_class_method :batch_organization_lookup

  def self.batch_article_lookup(pairs, existing_user_lookup, existing_org_lookup)
    return if pairs.empty?

    unique_pairs = pairs.uniq
    paths = unique_pairs.map { |owner, slug| "/#{owner}/#{slug}" }
    by_path = Article.where(path: paths).pluck(:path, :id).to_h

    unresolved = unique_pairs.reject { |owner, slug| by_path.key?("/#{owner}/#{slug}") }
    return by_path if unresolved.empty?

    resolve_author_path_articles(unresolved, by_path, existing_user_lookup)
    still_unresolved = unresolved.reject { |owner, slug| by_path.key?("/#{owner}/#{slug}") }
    resolve_legacy_org_articles(still_unresolved, by_path, existing_org_lookup) if still_unresolved.any?
    by_path
  end
  private_class_method :batch_article_lookup

  def self.resolve_author_path_articles(unresolved, by_path, existing_user_lookup)
    missing_owners = unresolved.map(&:first).uniq - (existing_user_lookup&.keys || [])
    user_map = (existing_user_lookup || {}).merge(batch_pluck_downcase(User, :username, missing_owners) || {})
    unresolved_user_ids = unresolved.filter_map { |owner, _slug| user_map[owner] }.uniq
    return if unresolved_user_ids.empty?

    user_articles = Article
      .where(user_id: unresolved_user_ids, slug: unresolved.map(&:last).uniq)
      .pluck(:user_id, :slug, :id)
      .to_h { |user_id, slug, id| [[user_id, slug.downcase], id] }

    unresolved.each do |owner, slug|
      found_id = user_articles[[user_map[owner], slug]]
      by_path["/#{owner}/#{slug}"] = found_id if found_id
    end
  end
  private_class_method :resolve_author_path_articles

  def self.resolve_legacy_org_articles(unresolved, by_path, existing_org_lookup)
    missing_owners = unresolved.map(&:first).uniq - (existing_org_lookup&.keys || [])
    org_map = (existing_org_lookup || {}).merge(batch_organization_lookup(missing_owners) || {})
    unresolved_org_ids = unresolved.filter_map { |owner, _slug| org_map[owner] }.uniq
    return if unresolved_org_ids.empty?

    org_articles = Article
      .where(organization_id: unresolved_org_ids, slug: unresolved.map(&:last).uniq)
      .pluck(:organization_id, :slug, :id)
      .to_h { |org_id, slug, id| [[org_id, slug.downcase], id] }

    unresolved.each do |owner, slug|
      found_id = org_articles[[org_map[owner], slug]]
      by_path["/#{owner}/#{slug}"] = found_id if found_id
    end
  end
  private_class_method :resolve_legacy_org_articles

  def self.lookup_reference(entry, lookups)
    key = entry[:key]
    return [nil, nil] if key.blank?

    kind = entry[:kind]
    if (type_name = SIMPLE_KIND_TYPES[kind])
      resolved_id = lookups[kind]&.dig(key)
      return ["Tag", resolved_id] if entry[:tag_name] == "feed" && kind == :tag

      return pair_if_present(type_name, resolved_id)
    end

    lookup_composite_reference(kind, key, lookups)
  end
  private_class_method :lookup_reference

  def self.lookup_composite_reference(kind, key, lookups)
    case kind
    when :article
      pair_if_present("Article", lookups[:article]&.dig("/#{key[0]}/#{key[1]}"))
    when :article_or_podcast
      podcast_id = lookups[:podcast]&.dig(key[0])
      podcast_id ? ["Podcast", podcast_id] : pair_if_present("Article", lookups[:article]&.dig("/#{key[0]}/#{key[1]}"))
    when :user_or_organization
      user_id = lookups[:user]&.dig(key)
      user_id ? ["User", user_id] : pair_if_present("Organization", lookups[:organization]&.dig(key))
    else
      [nil, nil]
    end
  end
  private_class_method :lookup_composite_reference

  def self.pair_if_present(type_name, id)
    id ? [type_name, id] : [nil, nil]
  end
  private_class_method :pair_if_present

  def self.derive_reference(tag_name, identifier)
    normalized_tag = tag_name.to_s.downcase
    raw_identifier = identifier.to_s.strip
    return [nil, nil] if raw_identifier.blank?

    url_token = raw_identifier.split.first || raw_identifier
    resolved = resolve_references([[normalized_tag, url_token, raw_identifier]]).first
    return [nil, nil] unless resolved

    [resolved[:referenced_type], resolved[:referenced_id]]
  end

  def self.extract_embed_url(url, options)
    options.to_s.split.detect { |part| part.match?(%r{\Ahttps?://}i) } || url.to_s.strip
  end
  private_class_method :extract_embed_url

  def self.classify_internal_embed(raw_url, domains)
    uri = parse_internal_uri(raw_url, domains, allow_relative: false)
    return [:none, nil] unless uri

    path = uri.path.to_s
    return [:none, nil] if path.blank? || path == "/"

    if path.start_with?("/t/")
      tag_name = path.delete_prefix("/t/").split("/").first
      return tag_name.present? ? [:tag, tag_name.downcase] : [:none, nil]
    end

    if (comment_match = path.match(COMMENT_PATH_REGEX))
      return [:comment, comment_match[:comment_id]]
    end

    segments = path.split("/").compact_blank
    case segments.size
    when 1
      [:user_or_organization, segments[0].downcase]
    when 2
      return [:none, nil] if segments[0].casecmp("events").zero?

      [:article_or_podcast, [segments[0].downcase, segments[1].downcase]]
    else
      [:none, nil]
    end
  end
  private_class_method :classify_internal_embed

  def self.extract_internal_owner_and_slug(raw_input, domains, allow_relative:)
    cleaned = raw_input.to_s.strip
    return if cleaned.blank?

    uri = parse_internal_uri(cleaned, domains, allow_relative: allow_relative)
    return unless uri

    segments = uri.path.to_s.split("/").compact_blank
    return unless segments.size == 2

    [segments[0].downcase, segments[1].downcase]
  end
  private_class_method :extract_internal_owner_and_slug

  def self.extract_single_segment_identifier(raw_input, domains)
    cleaned = raw_input.to_s.strip
    return if cleaned.blank?

    if cleaned.match?(%r{\Ahttps?://}i)
      uri = parse_internal_uri(cleaned, domains, allow_relative: false)
      return unless uri

      segments = uri.path.to_s.split("/").compact_blank
      segments.first
    else
      cleaned.delete_prefix("/").delete_suffix("/").presence
    end
  end
  private_class_method :extract_single_segment_identifier

  def self.extract_tag_identifier(raw_input, domains)
    cleaned = raw_input.to_s.strip
    return if cleaned.blank?

    if cleaned.match?(%r{\Ahttps?://}i)
      uri = parse_internal_uri(cleaned, domains, allow_relative: false)
      return unless uri

      path = uri.path.to_s
      path.start_with?("/t/") ? path.delete_prefix("/t/").split("/").first : nil
    else
      cleaned.delete_prefix("/t/").delete_prefix("/").delete_suffix("/").presence
    end
  end
  private_class_method :extract_tag_identifier

  def self.extract_comment_id_code(raw_input, domains)
    cleaned = raw_input.to_s.strip
    return if cleaned.blank?

    if cleaned.match?(%r{\Ahttps?://}i)
      uri = parse_internal_uri(cleaned, domains, allow_relative: false)
      return unless uri

      uri.path.to_s.match(COMMENT_PATH_REGEX)&.named_captures&.dig("comment_id")
    else
      cleaned.match(COMMENT_ID_REGEX)&.named_captures&.dig("comment_id")
    end
  end
  private_class_method :extract_comment_id_code

  def self.parse_internal_uri(raw_input, domains, allow_relative:)
    if raw_input.match?(%r{\Ahttps?://}i)
      uri = URI.parse(raw_input)
      host = uri.host&.downcase&.delete_prefix("www.")
      return if host.blank?

      host_with_port = uri.port && [80, 443].exclude?(uri.port) ? "#{host}:#{uri.port}" : host
      return unless domains.include?(host_with_port) || domains.include?(host)

      uri
    elsif allow_relative && raw_input.exclude?("://")
      normalized_path = raw_input.start_with?("/") ? raw_input : "/#{raw_input}"
      URI.parse(normalized_path)
    end
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :parse_internal_uri

  def self.internal_domains
    candidates = [
      Settings::General.app_domain,
      ApplicationConfig["APP_DOMAIN"],
      "localhost:#{URL.dev_port}",
      default_url_host,
    ]
    candidates.concat(Subforem.cached_domains) if defined?(Subforem) && Subforem.respond_to?(:cached_domains)

    domains = Set.new
    candidates.compact_blank.each do |domain|
      normalized = domain.to_s.strip.downcase.sub(%r{\Ahttps?://}, "").delete_prefix("www.").chomp("/")
      next if normalized.blank?

      domains << normalized
      domains << normalized.split(":").first
    end
    domains
  end
  private_class_method :internal_domains

  def self.default_url_host
    URI.parse(URL.url).host
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :default_url_host
end
