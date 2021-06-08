class ReplitTag < LiquidTagBase
  PARTIAL = "liquids/replit".freeze
  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid replit Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id =~ %r{\A@\w{2,15}/[a-zA-Z0-9\-]{0,60}\Z}
  end
end

Liquid::Template.register_tag("replit", ReplitTag)
