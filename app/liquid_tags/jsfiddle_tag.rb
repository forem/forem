class JSFiddleTag < LiquidTagBase
  PARTIAL = "liquids/jsfiddle".freeze

  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @build_options = parse_options(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        link: @link,
        build_options: @build_options,
        height: 600
      },
    )
  end

  private

  def valid_option(option)
    option.match(/^(js|html|css|result|,)*\z/)
  end

  def parse_options(input)
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    _, *options = stripped_link.split(" ")

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    validated_options.length.zero? ? "" : validated_options.join(",").concat("/")
  end

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise StandardError, "Invalid JSFiddle URL" unless valid_link?(the_link)

    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~ /^(http|https):\/\/(jsfiddle\.net)\/[a-zA-Z0-9\-\/]*\z/).zero?
  end
end

Liquid::Template.register_tag("jsfiddle", JSFiddleTag)
