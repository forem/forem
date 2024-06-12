class CardTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/card".freeze
  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        content: super
      },
    )
  end
end

Liquid::Template.register_tag("card", CardTag)
