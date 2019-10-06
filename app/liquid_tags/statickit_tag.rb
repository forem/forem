class StatickitTag < LiquidTagBase
  PARTIAL = "liquids/statickit".freeze

  def initialize(tag_name, id, tokens)
    super
    @id = id.strip
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end
end

Liquid::Template.register_tag("statickit", StatickitTag)
