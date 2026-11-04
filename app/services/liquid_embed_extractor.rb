class LiquidEmbedExtractor
  # We implemented a non-rendering parser scanning body_markdown directly to avoid instantiating Liquid tags.
  # This prevents background sync jobs from invoking Pundit auth, HTTP network requests (like UnifiedEmbed fetching
  # OpenGraph data), or halting the extraction entirely if a single tag fails Liquid::Template context validations.
  LIQUID_TAG_REGEX = /\{%\s*([a-zA-Z0-9_]+)\s+(.*?)\s*%\}/

  def self.extract(record)
    content = record.respond_to?(:body_markdown) ? record.body_markdown : nil
    return [] if content.blank?

    text = content.to_s
    raw_tags = ForemNative.extract_liquid_embed_tags(text) || legacy_extract_tags(text)
    return [] if raw_tags.empty?

    resolve_references(raw_tags)
  end

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
    lookups = build_reference_lookups(raw_tags)

    raw_tags.map do |tag_name, url, options|
      ref_type, ref_id = lookup_reference(tag_name, url, lookups)
      {
        tag_name: tag_name,
        url: url,
        options: options,
        referenced_type: ref_type,
        referenced_id: ref_id
      }
    end
  end
  private_class_method :resolve_references

  def self.build_reference_lookups(raw_tags)
    buckets = Hash.new { |h, k| h[k] = [] }
    raw_tags.each do |tag_name, url, _options|
      buckets[tag_name] << url
    end

    org_slugs = buckets["organization"] + buckets["org_posts"]
    {
      "user" => batch_pluck(User, :username, buckets["user"]),
      "comment" => batch_pluck(Comment, :id_code, buckets["comment"]),
      "tag" => batch_pluck(Tag, :name, buckets["tag"]),
      "podcast" => batch_pluck(Podcast, :slug, buckets["podcast"]),
      "organization" => batch_pluck(Organization, :slug, org_slugs)
    }
  end
  private_class_method :build_reference_lookups

  def self.batch_pluck(model, column, values)
    return if values.empty?

    model.where(column => values.uniq).pluck(column, :id).to_h
  end
  private_class_method :batch_pluck

  def self.lookup_reference(tag_name, url, lookups)
    case tag_name
    when "user"
      pair_if_present("User", lookups["user"]&.dig(url))
    when "comment"
      pair_if_present("Comment", lookups["comment"]&.dig(url))
    when "tag"
      pair_if_present("Tag", lookups["tag"]&.dig(url))
    when "podcast"
      pair_if_present("Podcast", lookups["podcast"]&.dig(url))
    when "organization", "org_posts"
      pair_if_present("Organization", lookups["organization"]&.dig(url))
    when "embed"
      derive_embed_reference(url)
    else
      [nil, nil]
    end
  end
  private_class_method :lookup_reference

  def self.pair_if_present(type_name, id)
    id ? [type_name, id] : [nil, nil]
  end
  private_class_method :pair_if_present

  def self.derive_reference(tag_name, identifier)
    case tag_name
    when "user"
      pair_if_present("User", User.where(username: identifier).pick(:id))
    when "comment"
      pair_if_present("Comment", Comment.where(id_code: identifier).pick(:id))
    when "tag"
      pair_if_present("Tag", Tag.where(name: identifier).pick(:id))
    when "podcast"
      pair_if_present("Podcast", Podcast.where(slug: identifier).pick(:id))
    when "organization", "org_posts"
      pair_if_present("Organization", Organization.where(slug: identifier).pick(:id))
    when "embed"
      derive_embed_reference(identifier)
    else
      [nil, nil]
    end
  end

  def self.derive_embed_reference(identifier)
    # If tag is explicitly embed, map internal Article urls without running ActionDispatch logic natively.
    app_domain = Settings::General.app_domain || "localhost:#{URL.dev_port}"
    return [nil, nil] unless identifier.include?(app_domain)

    path = URI.parse(identifier).path
    return [nil, nil] if path.blank?

    segments = path.split("/")
    return [nil, nil] if segments.size < 3

    article_id = Article.joins(:user).where(users: { username: segments[1] }, slug: segments[2]).pick(:id)
    pair_if_present("Article", article_id)
  rescue URI::InvalidURIError
    [nil, nil]
  end
  private_class_method :derive_embed_reference
end
