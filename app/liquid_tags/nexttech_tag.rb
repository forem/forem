class NextTechTag < LiquidTagBase
  PARTIAL = "liquids/nexttech".freeze

  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        link: @link
      },
    )
  end

  private

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    split_link = stripped_link.split(" ").first
    # Remove query string
    parsed_link = URI.parse(split_link)
    parsed_link.fragment = parsed_link.query = nil
    the_link = parsed_link.to_s
    raise_error unless valid_link?(the_link)
    "#{the_link}?embed=true"
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~
      /\A(http|https):\/\/((?:www\.)?next\.tech)\/projects\/\w+-\w+-[a-z0-9]+\/share(|\/|(?:\?ref=[a-z0-9]+)?)\Z/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid Next Tech URL"
  end
end

Liquid::Template.register_tag("nexttech", NextTechTag)
