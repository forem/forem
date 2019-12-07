class GithubTag < LiquidTagBase
  CODE_REGEXP = /#L\d+/.freeze

  def initialize(tag_name, link, tokens)
    super
    @tag_name = tag_name
    @link = link
    @tokens = tokens
    @rendered = pre_render
  end

  def issue_or_readme
    if @link.match(CODE_REGEXP)
      "code"
    elsif @link.include?("issues") || @link.include?("pull")
      "issue"
    else
      "readme"
    end
  end

  def pre_render
    if issue_or_readme == "issue"
      GithubTag::GithubIssueTag.new(@link).render
    elsif issue_or_readme == "readme"
      GithubTag::GithubReadmeTag.new(@link).render
    elsif issue_or_readme == "code"
      GithubTag::GithubCodeTag.new(@link).render
    end
  rescue StandardError => e
    raise StandardError, e.message
  end

  def render(*)
    @rendered
  end
end

Liquid::Template.register_tag("github", GithubTag)
