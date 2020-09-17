class GithubTag < LiquidTagBase
  def initialize(_tag_name, link, _parse_context)
    super
    @link = link
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
