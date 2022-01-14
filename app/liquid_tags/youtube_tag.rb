class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{https?://(?:www\.)?(?:youtube\.com|youtu\.be)/(?:embed/|watch\?v=)?(?<video_id>[a-zA-Z0-9_-]{11})(?:(?:&|\?)(?:t=|start=)(?<time_parameter>(?:\d{1,}h)?(?:\d{1,2}m)?(?:\d{1,2}s)?))?}
  VALID_ID_REGEXP = /\A(?<video_id>[a-zA-Z0-9_-]{11})(?:(?:&|\?)(?:t=|start=)(?<time_parameter>(?:\d{1,}h)?(?:\d{1,2}m)?(?:\d{1,2}s)?))?\Z/
  # rubocop:enable Layout/LineLength
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  MARKER_TO_SECONDS_MAP = {
    "h" => 60 * 60,
    "m" => 60,
    "s" => 1
  }.freeze

  def initialize(_tag_name, id, _parse_context)
    super

    input   = CGI.unescape_html(strip_tags(id))
    @id     = parse_id_or_url(input)
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

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, "Invalid YouTube ID" unless match

    video_id       = match[:video_id]
    time_parameter = match[:time_parameter]

    return video_id if time_parameter.blank?

    translate_start_time(video_id, time_parameter)
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
