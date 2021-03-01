class SpeakerdeckTag < LiquidTagBase
  PARTIAL = "liquids/speakerdeck".freeze

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
    raise StandardError, "Invalid Speakerdeck Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id =~ /\A[a-z\d]{32}\Z/i
  end
end

Liquid::Template.register_tag("speakerdeck", SpeakerdeckTag)
