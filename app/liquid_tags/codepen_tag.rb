class CodepenTag < LiquidTagBase
  PARTIAL = "liquids/codepen".freeze

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
        height: 600,
        build_options: @build_options
      },
    )
  end

  private

  def valid_option(option)
    option.match(/(default-tab\=\w+(\,\w+)?)/)
  end

  def parse_options(input)
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    _, *options = stripped_link.split(" ")

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    option = validated_options.join("&")

    option.presence || "default-tab=result"
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
      /^(http|https):\/\/(codepen\.io|codepen\.io\/team)\/[a-zA-Z0-9_\-]{1,20}\/pen\/([a-zA-Z]{5,7})\/{0,1}\z/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid CodePen URL"
  end
end

Liquid::Template.register_tag("codepen", CodepenTag)
