class StackblitzTag < LiquidTagBase
  PARTIAL = "liquids/stackblitz".freeze
  ID_REGEXP = /\A[a-zA-Z0-9\-]{0,60}\z/
  VIEW_OPTION_REGEXP = /\Aview=(preview|editor|both)\z/
  FILE_OPTION_REGEXP = /\Afile=(.*)\z/

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
    @view = parse_input(id, method(:valid_view?))
    @file = parse_input(id, method(:valid_file?))
    @height = 500
  end

  def render(_context)
    ApplicationController.render(
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
    id =~ ID_REGEXP
  end

  def parse_id(input)
    input_no_space = input.split.first
    raise StandardError, "Invalid Stackblitz Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def parse_input(input, validator)
    inputs = input.split

    # Validation
    validated_views = inputs.map { |input_option| validator.call(input_option) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless validated_views.length.between?(0, 1)

    validated_views.length.zero? ? "" : validated_views.join.to_s
  end

  def valid_view?(option)
    option.match(VIEW_OPTION_REGEXP)
  end

  def valid_file?(option)
    option.match(FILE_OPTION_REGEXP)
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)
