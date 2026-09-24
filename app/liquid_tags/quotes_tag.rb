class QuotesTag < Liquid::Block
  PARTIAL = "liquids/quotes".freeze

  def initialize(tag_name, markup, parse_context)
    super
    raise StandardError, I18n.t("liquid_tags.quotes_tag.no_args") if markup.strip.present?
  end

  def render(context)
    content = @body.nodelist.filter_map do |node|
      node.render(context) if node.is_a?(QuoteTag)
    end.join("\n")

    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content },
    ).gsub(/>\s*\n\s*</, "> <").strip
  end
end

Liquid::Template.register_tag("quotes", QuotesTag)
