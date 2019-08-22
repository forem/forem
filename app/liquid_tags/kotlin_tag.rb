class KotlinTag < LiquidTagBase
  PARTIAL = "liquids/kotlin".freeze

  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 600,
        theme: "dracula"
      },
    )
  end

  private

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise_error unless valid_link?(the_link)
    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~
      /^(http|https):\/\/(pl.kotl.in)\/[a-zA-Z0-9_\-]{1,30}/)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid Kotlin Playground URL"
  end
end

Liquid::Template.register_tag("kotlin", KotlinTag)
