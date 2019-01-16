class JSFiddleTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @build_options = parse_options(link)
    @height = 600
  end

  def render(_context)
    html = <<-HTML
      <iframe
        src="#{@link}/embedded/#{@build_options}/dark"
        width="100%"
        height="#{@height}"
        scrolling="no"
        frameborder="no"
        allowfullscreen
        allowtransparency="true">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def valid_option(option)
    option.match(/^(js|html|css|result|,)*\z/)
  end

  def parse_options(input)
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    _, *options = stripped_link.split(" ")

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject { |e| e == nil }
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    options.join
  end

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise_error unless valid_link?(the_link)
    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~ /^(http|https):\/\/(jsfiddle\.net)\/[a-zA-Z0-9\-\/]*\z/).zero?
  end

  def raise_error
    raise StandardError, "Invalid JSFiddle URL"
  end
end

Liquid::Template.register_tag("jsfiddle", JSFiddleTag)
