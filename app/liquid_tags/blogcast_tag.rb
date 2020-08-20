class BlogcastTag < LiquidTagBase
  PARTIAL = "liquids/blogcast".freeze
  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid Blogcast Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    (id =~ /\A\d{1,9}\Z/i)&.zero?
  end
end

Liquid::Template.register_tag("blogcast", BlogcastTag)
