class SlideshareTag < LiquidTagBase
  def initialize(tag_name, key, tokens)
    super
    @key    = validate key.strip
    @height = 450
  end

  def render(_context)
    finalize_html <<-HTML
      <iframe
        src="//www.slideshare.net/slideshow/embed_code/key/#{@key}"
        alt="#{@key} on slideshare.net"
        width="100%"
        height="#{@height}"
        frameborder="0"
        scrolling="no"
        allowfullscreen>
      </iframe>
    HTML
  end

  private

  def validate(key)
    if key.match?(/\A[a-zA-Z0-9]{14}\Z/)
      key.strip
    else
      raise StandardError, "Invalid Slideshare Key"
    end
  end
end

Liquid::Template.register_tag("slideshare", SlideshareTag)
