class CardTag < Liquid::Block
  include LiquidTagHelpers

  PARTIAL = "liquids/card".freeze

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        content: sanitize_block_content(super)
      },
    )
  end
end

Liquid::Template.register_tag("card", CardTag)
