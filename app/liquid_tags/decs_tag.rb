class DecsTag < LiquidTagBase
  PARTIAL = "liquids/decs".freeze

  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @snippet = parse_url_for_decs_snippet(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        link: @snippet["url"],
        height: @snippet["height"]
      },
    )
  end

  def parse_url_for_decs_snippet(url)
    sanitized_article_url = ActionController::Base.helpers.strip_tags(url).strip

    DECSSnippetService.new("https://www.decs.xyz/oembed?url=" + sanitized_article_url).call
  rescue StandardError
    raise_error
  end

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise_error unless valid_link?(the_link)
    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~ /^(https):\/\/(www\.decs\.xyz)\/[a-zA-Z0-9\.\-\/]*\/[a-zA-Z0-9\.\-\/]*\z/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid DECS Code Snippet URL"
  end
end

Liquid::Template.register_tag("decs", DecsTag)
