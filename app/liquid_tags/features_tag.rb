class FeaturesTag < Liquid::Block
  PARTIAL = "liquids/features".freeze

  def initialize(tag_name, markup, parse_context)
    super
    markup = markup.strip
    raise StandardError, I18n.t("liquid_tags.features_tag.no_args") if markup.present?
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content },
    )
  end
end

Liquid::Template.register_tag("features", FeaturesTag)
