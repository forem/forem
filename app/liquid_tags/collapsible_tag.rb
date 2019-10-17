class CollapsibleTag < Liquid::Block
  PARTIAL = "liquids/collapsible".freeze

  def initialize(_tag, summary, _tokens)
    super
    @summary = ActionController::Base.helpers.strip_tags(summary).strip
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { summary: @summary, content: parsed_content },
    )
  end
end

Liquid::Template.register_tag("collapsible", CollapsibleTag)
