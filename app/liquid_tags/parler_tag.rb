class ParlerTag < LiquidTagBase
  PARTIAL = "liquids/parler".freeze

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        height: 120,
        width: 710
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    input_no_space = input_no_space.scan(%r{\bhttps?://[a-z./0-9-]+\b}).first
    raise StandardError, I18n.t("liquid_tags.parler_tag.invalid_parler_url") unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id =~ %r{\A(https://www.parler.io/audio/\d{1,11}/[a-zA-Z0-9]{11,40}.[0-9a-zA-Z-]{11,36}.mp3)\Z}
  end
end

Liquid::Template.register_tag("parler", ParlerTag)
