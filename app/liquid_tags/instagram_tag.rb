class InstagramTag < LiquidTagBase
  PARTIAL = "liquids/instagram".freeze

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
    raise StandardError, "Invalid Instagram Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id.length == 11 && id =~ /[a-zA-Z0-9_-]{11}/
  end
end

Liquid::Template.register_tag("instagram", InstagramTag)
