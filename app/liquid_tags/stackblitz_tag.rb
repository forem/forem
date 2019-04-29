class StackblitzTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @view = parse_input(input, valid_view?)
    @file = parse_input(input, valid_file?)
    @height = 500
  end

  def render(_context)
    html = <<-HTML
      <iframe
        src="https://stackblitz.com/edit/#{@id}?embed=1#{@view}#{@file}"
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
    raise StandardError, "Invalid Stackblitz Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def parse_input(input, validator)
    input_split = input.split(" ")

    # Validation
    validated_views = input_split.map { |o| validator.call(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless validated_views.length.between?(0, 1)

    validated_views.length.zero? ? "" : "&#{validated_views.join('')}"
  end

  def valid_view?(option)
    option.match(/^view=(preview|editor|both)\z/)
  end

  def valid_file?(option)
    option.match(/^file=(.*)\z/)
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)
