class SlidesTag < Liquid::Block
  PARTIAL = "liquids/slides".freeze

  def initialize(tag_name, markup, parse_context)
    super
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content },
    )
  end
end

Liquid::Template.register_tag("slides", SlidesTag)
