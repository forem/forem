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
    striped_link = ActionController::Base.helpers.strip_tags(link)
    raise_error unless valid_link?(striped_link)
    striped_link.gsub("/pen/", "/embed/")
  end

  def valid_link?(link)
    # TODO: the ideal link should look like below
    # https://codepen.io/{sjdklfjsdklf}/embed/{sjdklfjsldf}
    link.include?("codepen.io")
  end

  def raise_error
    raise StandardError, "Invalid CodePen URL"
  end
end

Liquid::Template.register_tag("codepen", CodepenTag)
