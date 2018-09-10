class GlitchTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    html = <<-HTML
      <div class="glitch-embed-wrap" style="height: 450px; width: 100%;margin: 1em auto 1.3em">
        <iframe
          sandbox="allow-same-origin allow-scripts allow-forms"
          src="https://glitch.com/embed/#!/embed/#{@id}?path=index.html"
          alt="#{@id} on glitch"
          style="height: 100%; width: 100%; border: 0;margin:0;padding:0"></iframe>
      </div>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid Glitch ID" unless valid_id?(input_no_space)
    input_no_space
  end

  def valid_id?(input)
    (input =~ /^[a-zA-Z0-9\-]{1,110}$/)&.zero?
  end
end

Liquid::Template.register_tag("glitch", GlitchTag)
