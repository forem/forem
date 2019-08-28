class ReplitTag < LiquidTagBase
  PARTIAL = "liquids/replit".freeze
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid repl.it Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id =~ /\A\@[\w]{2,15}\/[a-zA-Z0-9\-]{0,60}\Z/
  end
end

Liquid::Template.register_tag("replit", ReplitTag)
