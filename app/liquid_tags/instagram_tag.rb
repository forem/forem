class InstagramTag < LiquidTagBase
  PARTIAL = "liquids/instagram".freeze

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
    raise StandardError, "Invalid Instagram Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id.length == 11 && id =~ /[a-zA-Z0-9_-]{11}/
  end
end

Liquid::Template.register_tag("instagram", InstagramTag)
