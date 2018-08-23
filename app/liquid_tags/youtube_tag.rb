class YoutubeTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @width = 710
    @height = 399
  end

  def render(_context)
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
    input = translate_url(input) if input.include?("watch?v=")
    input = translate_start_time(input) if input.include?("?t=")
    input_no_space = input.delete(" ")
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid Youtube Id"
    end
  end

  def translate_url(input)
    input.split("watch?v=")[1].split("\"")[0]
  end

  def translate_start_time(id)
    time = id.split("?t=")[-1]
    if /(\d+)m(\d+)s/.match?(time)
      time = time.scan(/(\d+)m(\d+)s/)[0].map(&:to_i)
      seconds = time[1] + (time[0] * 60)
      "#{id.split('?t=')[0]}?start=#{seconds}"
    end
  end

  def valid_id?(id)
    id =~ /[a-zA-Z0-9_-]{11}(\?start\=\d*)?/
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)
