class SpeakerdeckTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(context)
    html = <<-HTML
      <iframe allowfullscreen="true"
        allowtransparency="true"
        frameborder="0"
        height="463"
        id="talk_frame_#{@id}"
        mozallowfullscreen="true"
        src="//speakerdeck.com/player/#{@id}"
        style="border:0; padding:0; margin:0; background:transparent;"
        webkitallowfullscreen="true"
        width="710"></iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid Speakerdeck Id"
    end
  end

  def valid_id?(id)
    !!(id =~ /\A[a-z\d]*\Z/i)
  end
end
