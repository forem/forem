class StackblitzTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @view = parse_view(id)
    @height = 500
  end

  def render(_context)
    html = <<-HTML
      <iframe
        src="https://stackblitz.com/edit/#{@id}?embed=1&#{@view}"
        width="100%"
        height="#{@height}"
        scrolling="no"
        frameborder="no"
        allowfullscreen
        allowtransparency="true">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end

  def parse_id(input)
    input_no_space = input.split(" ").first
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid Stackblitz Id"
    end
  end

  def parse_view(input)
    input_split = input.split(" ")

    # Validation
    validated_views = input_split.map { |o| valid_view?(o) }.reject { |e| e == nil }
    raise StandardError, "Invalid Options" unless validated_views.length  <= 1

    validated_views.length.zero? ? "" : validated_views.join("")
  end

  def valid_view?(option)
    option.match(/^view=(preview|editor|both)\z/)
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)
