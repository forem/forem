class VimeoTag < LiquidTagBase
  def initialize(tag_name, token, tokens)
    super
    @id     = id_for token
    @width  = 710
    @height = 399
  end

  def render(_context)
    finalize_html <<~HTML
      <iframe
        src="https://player.vimeo.com/video/#{@id}"
        width="#{@width}"
        height="#{@height}"
        frameborder="0"
        webkitallowfullscreen
        mozallowfullscreen
        allowfullscreen>
      </iframe>
    HTML
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
