class CodepenTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @build_options = parse_options(link)
    @height = 600
  end

  def render(_context)
    html = <<-HTML
      <iframe height="#{@height}"
        src="#{@link}?height=#{@height}&#{@build_options}&embed-version=2"
        scrolling="no"
        frameborder="no"
        allowtransparency="true"
        style="width: 100%;">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def valid_option(option)
    option.match(/(default-tab\=\w(\,\w)?)/)
  end

  def parse_options(input)
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    _, *options = stripped_link.split(" ")

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject { |e| e == nil }
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    option = options.join("&")

    if option.blank?
      "default-tab=result"
    else
      option
    end
  end

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise_error unless valid_link?(the_link)
    the_link.gsub("/pen/", "/embed/")
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~
      /^(http|https):\/\/(codepen\.io)\/[a-zA-Z0-9\-]{1,20}\/pen\/([a-zA-Z]{5,7})\/{0,1}\z/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid CodePen URL"
  end
end

Liquid::Template.register_tag("codepen", CodepenTag)
