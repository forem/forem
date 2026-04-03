class LiquidEmbedExtractor
  # We implemented a non-rendering parser scanning body_markdown directly to avoid instantiating Liquid tags.
  # This prevents background sync jobs from invoking Pundit auth, HTTP network requests (like UnifiedEmbed fetching OpenGraph data),
  # or halting the extraction entirely if a single tag fails Liquid::Template context validations.
  LIQUID_TAG_REGEX = /\{%\s*([a-zA-Z0-9_]+)\s+(.*?)\s*%\}/

  def self.extract(record)
    content = record.respond_to?(:body_markdown) ? record.body_markdown : nil
    return [] if content.blank?

    # Strip codeblocks to reliably extract active tags only natively
    stripped_content = content.to_s.gsub(/```.*?```/m, "").gsub(/`.*?`/, "")

    tags = []
    stripped_content.scan(LIQUID_TAG_REGEX).each do |match|
      tag_name = match[0].downcase
      options = match[1].strip
      url = options.split(" ").first || options

      ref_type, ref_id = derive_reference(tag_name, url)

      tags << {
        tag_name: tag_name,
        url: url,
        options: options,
        referenced_type: ref_type,
        referenced_id: ref_id
      }
    end

    tags.uniq { |t| [t[:tag_name], t[:url], t[:options]] }
  end

  def self.derive_reference(tag_name, identifier)
    case tag_name
    when "user"
      user = User.find_by(username: identifier)
      [user&.class&.name, user&.id]
    when "comment"
      comment = Comment.find_by(id_code: identifier)
      [comment&.class&.name, comment&.id]
    when "tag"
      tag = Tag.find_by(name: identifier)
      [tag&.class&.name, tag&.id]
    when "podcast"
      podcast = Podcast.find_by(slug: identifier)
      [podcast&.class&.name, podcast&.id]
    when "organization"
      org = Organization.find_by(slug: identifier)
      [org&.class&.name, org&.id]
    when "embed"
      # If tag is explicitly embed, map internal Article urls without running ActionDispatch logic natively.
      app_domain = Settings::General.app_domain || "localhost:3000"
      if identifier.include?(app_domain)
        begin
          path = URI.parse(identifier).path
          if path.present?
            segments = path.split("/")
            if segments.size >= 3
              article = Article.joins(:user).find_by(users: { username: segments[1] }, slug: segments[2])
              return [article.class.name, article.id] if article
            end
          end
        rescue URI::InvalidURIError
          # safely ignore invalid payload URLs dynamically
        end
      end
      [nil, nil]
    else
      [nil, nil]
    end
  end
end
