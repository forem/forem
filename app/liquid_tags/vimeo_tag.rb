require "uri"

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
    File.basename URI(input.to_s.strip).path
  end
end

Liquid::Template.register_tag("vimeo", VimeoTag)
