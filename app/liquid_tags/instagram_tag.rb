class InstagramTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    html = <<-HTML
    <div class="instagram-position">
      <iframe
        id="instagram-liquid-tag"
        src="https://www.instagram.com/p/#{@id}/embed/captioned"
        allowtransparency="true"
        frameborder="0"
        data-instgrm-payload-id="instagram-media-payload-0"
        scrolling="no">
      </iframe>
      <script async defer src="https://platform.instagram.com/en_US/embeds.js"></script>
    </div>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid Instagram Id"
    end
  end

  def valid_id?(id)
    id.length == 11 && id =~ /[a-zA-Z0-9_-]{11}/
  end
end

Liquid::Template.register_tag("instagram", InstagramTag)
