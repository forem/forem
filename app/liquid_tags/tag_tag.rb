class TagTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "tags/liquid".freeze

  def initialize(_tag_name, tag, _parse_context)
    super
    @tag = parse_tag_name_to_tag(tag.delete(" "))
    @follow_btn = follow_button(@tag)
    @dark_color = dark_color(@tag)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        tag: @tag,
        follow_btn: @follow_btn,
        dark_color: @dark_color
      },
    )
  end

  private

  def dark_color(tag)
    Color::CompareHex.new([tag.bg_color_hex || "#0000000", tag.text_color_hex || "#ffffff"]).brightness(0.88)
  end

  def parse_tag_name_to_tag(input)
    tag = Tag.find_by(name: input)
    raise StandardError, "invalid tag name" if tag.nil?

    tag
  end
end

Liquid::Template.register_tag("tag", TagTag)
