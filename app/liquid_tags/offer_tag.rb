class OfferTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/offer".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @link = options["link"]
    @button_text = options["button"] || "Learn More"
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        button_text: @button_text,
        content: content,
      },
    )
  end

  private

  def parse_options(markup)
    cleaned = strip_tags(markup)
    options = {}
    cleaned.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = (quoted_val || plain_val).strip
    end
    options
  end
end

Liquid::Template.register_tag("offer", OfferTag)
