class RowTag < Liquid::Block
  PARTIAL = "liquids/row".freeze

  def initialize(tag_name, markup, parse_context)
    super
    markup = markup.strip
    raise StandardError, I18n.t("liquid_tags.row_tag.no_args") if markup.present?
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content },
    )
  end
end

Liquid::Template.register_tag("row", RowTag)
