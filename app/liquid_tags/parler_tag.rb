class ParlerTag < LiquidTagBase
  PARTIAL = "liquids/parler".freeze

  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
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
    input_no_space = input_no_space.scan(/\bhttps?:\/\/[a-z.\/0-9-]+\b/).first
    raise StandardError, "Invalid Parler URL" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    id =~ /\A(https:\/\/www.parler.io\/audio\/\d{1,11}\/[a-zA-Z0-9]{11,40}.[0-9a-zA-Z-]{11,36}.mp3)\Z/
  end
end

Liquid::Template.register_tag("parler", ParlerTag)
