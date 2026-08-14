class OfferTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper
  include LiquidTagHelpers

  PARTIAL = "liquids/offer".freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(fully_unescape_html(markup.strip))
    @link = options["link"]
    validate_url!(@link, "link")
    @button_text = options["button"] || I18n.t("liquid_tags.offer_tag.default_button")
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
end

Liquid::Template.register_tag("offer", OfferTag)
