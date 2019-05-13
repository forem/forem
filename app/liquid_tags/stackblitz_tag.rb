class StackblitzTag < LiquidTagBase
  PARTIAL = "liquids/stackblitz".freeze

  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @view = parse_input(id, method(:valid_view?))
    @file = parse_input(id, method(:valid_file?))
    @height = 500
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        id: @id,
        view: @view,
        file: @file,
        height: @height
      },
    )
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

    validated_views.length.zero? ? "" : validated_views.join("").to_s
  end

  def valid_view?(option)
    option.match(/^view=(preview|editor|both)\z/)
  end

  def valid_file?(option)
    option.match(/^file=(.*)\z/)
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)
