class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  MARKER_TO_SECONDS_MAP = {
    "h" => 60 * 60,
    "m" => 60,
    "s" => 1
  }.freeze

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid YouTube ID" unless valid_id?(input_no_space)
    return translate_start_time(input_no_space) if input_no_space.include?("?t=")

    input_no_space
  end

  def valid_id?(id)
    id.match?(/\A[a-zA-Z0-9_-]{11}((\?t=)?(\d{1,}h?)?(\d{1,2}m)?(\d{1,2}s)?){5,11}?\Z/)
  end

  def translate_start_time(id)
    time = id.split("?t=")[-1]
    return "#{id.split('?t=')[0]}?start=#{time}" if time.match?(/\A\d+\Z/)

    time_elements = time.split(/[a-z]/)
    time_markers = time.split(/\d+/)[1..]

    seconds = 0
    time_markers.each_with_index do |m, i|
      seconds += MARKER_TO_SECONDS_MAP.fetch(m, 0) * time_elements[i].to_i
    end

    "#{id.split('?t=')[0]}?start=#{seconds}"
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)
