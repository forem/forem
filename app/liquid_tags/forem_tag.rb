module ForemTag
  REGISTRY_REGEXP = %r{#{Regexp.escape(URL.url)}/\b([\w-]+)?}
  USER_ORG_REGEXP = %r{#{URL.url}/(?<name>[\w-]+)/?$}
  POST_PODCAST_REGEXP = %r{#{URL.url}/(?<podcast>[\w-]+)/[\w-]+/?}
  COMBINED_REGEXP = [USER_ORG_REGEXP, POST_PODCAST_REGEXP].freeze

  def self.new(tag_name, input, parse_context)
    link = process_input(input)
    klass = determine_klass(link)
    raise StandardError, "No LiquidTag for given #{Settings::Community.community_name} URL." unless klass

    klass.__send__(:new, tag_name, link, parse_context)
  end

  def self.process_input(input)
    stripped_input = ActionController::Base.helpers.strip_tags(input).strip
    CGI.unescape_html(stripped_input)
  end

  def self.determine_klass(link)
    return TagTag if link.start_with?("#{URL.url}/t/")
    return CommentTag if link.include?("/comment/")

    process_other_link_types(link)
  end

  def self.process_other_link_types(link)
    match = pattern_match_for(link, COMBINED_REGEXP)
    return unless match
    return user_or_org(match) if match.names.include?("name")
    return podcast_or_link(match) if match.names.include?("podcast")
  end

  def self.pattern_match_for(input, regex_options)
    regex_options
      .filter_map { |regex| input.match(regex) }
      .first
  end

  def self.user_or_org(match)
    return UserTag if User.find_by(username: match[:name], registered: true)
    return OrganizationTag if Organization.find_by(slug: match[:name])
  end

  def self.podcast_or_link(match)
    return PodcastTag if Podcast.find_by(slug: match[:podcast])

    LinkTag
  end
end

UnifiedEmbed.register(ForemTag, regexp: ForemTag::REGISTRY_REGEXP)
