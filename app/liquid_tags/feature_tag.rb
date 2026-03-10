class FeatureTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper
  include LiquidTagHelpers

  PARTIAL = "liquids/feature".freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @icon = options["icon"]
    @title = options["title"]
    raise StandardError, I18n.t("liquid_tags.feature_tag.missing_title") unless @title
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        icon: @icon,
        title: @title,
        content: content,
      },
    )
  end
end

Liquid::Template.register_tag("feature", FeatureTag)
