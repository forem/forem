class GithubTag < LiquidTagBase
  REGISTRY_REGEXP = %r{https://github\.com/[\w\-.]{1,39}/[\w\-.]{1,39}/?((issues|pull)/\d+((#issuecomment-|#discussion_|#pullrequestreview-)\w+)?)?(\sno-?readme\$)?}

  def initialize(_tag_name, link, _parse_context)
    super

    stripped_link  = strip_tags(link)
    unescaped_link = CGI.unescape_html(stripped_link)
    @link = unescaped_link
    @rendered = pre_render
  end

  def issue_or_readme
    if @link.include?("issues") || @link.include?("pull")
      "issue"
    else
      "readme"
    end
  end

  def pre_render
    case issue_or_readme
    when "issue"
      GithubTag::GithubIssueTag.new(@link).render
    when "readme"
      gt = GithubTag::GithubReadmeTag.new(@link)
      gt.render
    end
  rescue StandardError => e
    raise StandardError, e.message
  end

  def render(*)
    @rendered
  end
end

Liquid::Template.register_tag("github", GithubTag)

UnifiedEmbed.register(GithubTag, regexp: GithubTag::REGISTRY_REGEXP)
