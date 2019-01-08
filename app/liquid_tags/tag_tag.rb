class TagTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper

  def initialize(_tag_name, tag, _tokens)
    @tag = parse_tag_name_to_tag(tag)
  end

  def render(_context)
    # looks like link liquid tag
    <<-HTML
    <div class="ltag__tag ltag__tag__id__#{@tag.id}" style="border-color:#{dark_color};box-shadow: 3px 3px 0px #{dark_color}">
      <style>
        .ltag__tag__id__#{@tag.id} .follow-action-button{
          background-color: #{@tag.bg_color_hex} !important;
          color: #{@tag.text_color_hex} !important;
          border-color: #{@tag.bg_color_hex.to_s.casecmp('#ffffff').zero? ? @tag.text_color_hex : @tag.bg_color_hex} !important;
        }
      </style>
        <div class="ltag__tag__content">
          <h2>#<a href="/t/#{@tag.name}" class="ltag__tag__link">#{@tag.name}</a> #{follow_button(@tag)}</h2>
          <div class="ltag__tag__summary">
          #{@tag.short_summary}
          </div>
        </div>
    </div>
    HTML
  end

  private

  def dark_color
    HexComparer.new([@tag.bg_color_hex || "#0000000", @tag.text_color_hex || "#ffffff"]).brightness(0.88)
  end

  def parse_tag_name_to_tag(input)
    input_no_space = input.delete(" ")
    tag = Tag.find_by_name(input_no_space)
    if tag.nil?
      raise StandardError, "invalid tag name"
    else
      tag
    end
  end
end

Liquid::Template.register_tag("tag", TagTag)
