class CodepenTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @height = 600
  end

  def render(_context)
    html = <<-HTML
      <iframe height="#{@height}"
        src="#{@link}?height=500&default-tab=result&embed-version=2"
        scrolling="no"
        frameborder="no"
        allowtransparency="true"
        style="width: 100%;">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    raise_error unless valid_link?(stripped_link)
    stripped_link.gsub("/pen/", "/embed/")
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    URI.parse(link_no_space).host == "codepen.io" &&
      (link_no_space =~
        /^(http|https):\/\/(codepen\.io)\/[a-zA-Z0-9\-]{1,20}\/pen\/([a-zA-Z]{6})\z/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid CodePen URL"
  end
end

Liquid::Template.register_tag("codepen", CodepenTag)
