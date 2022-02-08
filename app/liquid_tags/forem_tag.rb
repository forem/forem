class ForemTag < LiquidTagBase
  REGISTRY_REGEXP = %r{#{URL.url}/\w+(/[\w-]+)?(/[\w-]+)?}
  USER_ORG_REGEXP = %r{#{URL.url}/(?<name>[\w-]+)/?$}
  POST_PODCAST_REGEXP = %r{#{URL.url}/(?<podcast>[\w-]+)/[\w-]+/?}
  COMBINED_REGEXP = [USER_ORG_REGEXP, POST_PODCAST_REGEXP].freeze

  def initialize(tag_name, link, parse_context)
    super

    stripped_link  = strip_tags(link)
    unescaped_link = CGI.unescape_html(stripped_link)
    @link = unescaped_link
    @rendered = pre_render(tag_name, parse_context)
  end

  def pre_render(tag_name, parse_context)
    case forem_link_type
    when "listings"
      render_tag(ListingTag, tag_name, @link, parse_context)
    when "tag"
      render_tag(TagTag, tag_name, @link, parse_context)
    when "user"
      render_tag(UserTag, tag_name, @link, parse_context)
    when "org"
      render_tag(OrganizationTag, tag_name, @link, parse_context)
    when "podcast"
      render_tag(PodcastTag, tag_name, @link, parse_context)
    when "link"
      render_tag(LinkTag, tag_name, @link, parse_context)
    else
      raise StandardError, "Invalid #{Settings::Community.community_name} URL."
    end
  rescue StandardError => e
    raise StandardError, e.message
  end

  def forem_link_type
    return "listings" if @link.include?("#{URL.url}/listings/")
    return "tag" if @link.include?("#{URL.url}/t/")

    process_other_link_types(@link)
  end

  def process_other_link_types(link)
    match = pattern_match_for(link, COMBINED_REGEXP)
    return unless match
    return user_or_org(match) if match.names.include?("name")
    return podcast_or_link(match) if match.names.include?("podcast")
  end

  def user_or_org(match)
    return "user" if User.find_by(username: match[:name], registered: true)
    return "org" if Organization.find_by(slug: match[:name])
  end

  def podcast_or_link(match)
    return "podcast" if Podcast.find_by(slug: match[:podcast])

    "link"
  end

  def render(*)
    @rendered
  end
end

UnifiedEmbed.register(ForemTag, regexp: ForemTag::REGISTRY_REGEXP)
