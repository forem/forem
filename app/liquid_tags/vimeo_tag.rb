class VimeoTag < LiquidTagBase
  PARTIAL = "liquids/vimeo".freeze

  def initialize(_tag_name, token, _parse_context)
    super
    @id     = id_for(token)
    @width  = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def id_for(input)
    # This was the original plan:
    #   require "uri"
    #   File.basename URI(input).path
    # But the markdown turns the link into html. This is simple enough,
    # works for all the use cases and isn't exploitable.
    input.to_s.scan(/\d+/).max_by(&:length)
  end
end

Liquid::Template.register_tag("vimeo", VimeoTag)
