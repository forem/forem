class ParlerTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @width = 710
    @height = 120
  end

  def render(_context)
    html = <<-HTML
    <iframe
      width="#{@width}"
      height="#{@height}"
      src="https://api.parler.io/ss/player?url=#{@id}">
    </iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    input_no_space = input_no_space.scan(/\bhttps?:\/\/[a-z.\/0-9-]+\b/).first
    raise StandardError, "Invalid Parler URL" unless valid_id?(input_no_space)
    input_no_space
  end

  def valid_id?(id)
    puts id
    id =~ /\A(https:\/\/www.parler.io\/audio\/\d{1,11}\/[a-zA-Z0-9]{11,40}.[0-9a-zA-Z-]{11,36}.mp3)\Z/
  end
end

Liquid::Template.register_tag("parler", ParlerTag)
