class SpeakerdeckTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    html = <<-HTML
      <div class="ltag_speakerdeck"
        style="position: relative;
          width: 100%;
          height: 0;
          padding-bottom: calc(57% + 58px);margin-bottom:1em auto 1.3em">
        <iframe allowfullscreen="true"
          allowtransparency="true"
          frameborder="0"
          height="463"
          id="talk_frame_#{@id}"
          mozallowfullscreen="true"
          src="//speakerdeck.com/player/#{@id}"
          style="border:0; padding:0; margin:0; background:transparent;position: absolute;
                  width: 100%;
                  height: 100%;
                  left: 0; top: 0;"
          webkitallowfullscreen="true"
          width="710"></iframe>
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
      raise StandardError, "Invalid Speakerdeck Id"
    end
  end

  def valid_id?(id)
    !!(id =~ /\A[a-z\d]*\Z/i)
  end
end

Liquid::Template.register_tag("speakerdeck", SpeakerdeckTag)
