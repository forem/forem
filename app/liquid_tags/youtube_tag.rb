class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{https?://(?:www\.)?(?:youtube\.com|youtu\.be)/(?:embed/|watch\?v=)?(?<video_id>[a-zA-Z0-9_-]{11})(?:\?|&)?(?:t=|start=)?(?<time_parameter>(?:\d{1,}h?)?(?:\d{1,2}m)?(?:\d{1,2}s)?{5,11})?}
  # rubocop:enable Layout/LineLength

  MARKER_TO_SECONDS_MAP = {
    "h" => 60 * 60,
    "m" => 60,
    "s" => 1
  }.freeze

  def initialize(_tag_name, id, _parse_context)
    super

    input   = strip_tags(id)
    url     = CGI.unescape_html(input)
    @id     = parse_id_or_url(url)
    @width  = 710
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

  def parse_id_or_url(url)
    video_id = url.match(REGISTRY_REGEXP)[:video_id]
    time_parameter = url.match(REGISTRY_REGEXP)[:time_parameter]

    raise StandardError, "Invalid YouTube ID" unless valid_id?(video_id)
    return video_id if time_parameter.blank?

    translate_start_time(video_id, time_parameter)
  end

  def valid_id?(id)
    id.match?(/\A[a-zA-Z0-9_-]{11}((\?|&)?(t=|start=)?(\d{1,}h?)?(\d{1,2}m)?(\d{1,2}s)?){5,11}?\Z/)
  end

  def translate_start_time(video_id, time_parameter)
    return "#{video_id}?start=#{time_parameter}" if time_parameter.match?(/\A\d+\Z/)

    time_elements = time_parameter.split(/[a-z]/)
    time_markers = time_parameter.split(/\d+/)[1..]

    seconds = 0
    time_markers.each_with_index do |m, i|
      seconds += MARKER_TO_SECONDS_MAP.fetch(m, 0) * time_elements[i].to_i
    end

    "#{video_id}?start=#{seconds}"
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)

UnifiedEmbed.register(YoutubeTag, regexp: YoutubeTag::REGISTRY_REGEXP)
