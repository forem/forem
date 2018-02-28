class YoutubeTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @width = 710
    @height = 399
  end

  def render(context)
    html = <<-HTML
    <iframe
      width="#{@width}"
      height="#{@height}"
      src="https://www.youtube.com/embed/#{@id}"
      allowfullscreen>
    </iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(' ')
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, 'Invalid Youtube Id'
    end
  end

  def valid_id?(id)
    id.length == 11 && !(id !~ /[a-zA-Z0-9_-]{11}/)
  end
end
