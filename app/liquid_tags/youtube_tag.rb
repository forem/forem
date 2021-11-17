class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  # rubocop:disable Layout/LineLength
  YOUTUBE_URL_REGEX = %r{https?://(www\.)?(youtube|youtu)\.(com|be)/(embed|watch)?(\?v=)?(/)?[a-zA-Z0-9_-]{11}((\?t=)?(\d{1,})?)?}
  # rubocop:enable Layout/LineLength

  def initialize(_tag_name, id, _parse_context)
    super

    # for if id is an unstripped URL; doesn't appear to affect bare youtube ids
    input = ActionController::Base.helpers.strip_tags(id).strip

    @id = parse_id_or_url(input)
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

  def parse_id_or_url(input)
    if (input =~ YOUTUBE_URL_REGEX)&.zero?
      extract_youtube_id(input)
    else
      input_no_space = input.delete(" ")
      raise StandardError, "Invalid YouTube ID" unless valid_id?(input_no_space)
      return translate_start_time(input_no_space) if input_no_space.include?("?t=")

      input_no_space
    end
  end

  def extract_youtube_id(url)
    url = url.gsub(/(>|<)/i, "").split(%r{(vi/|v=|/v/|youtu\.be/|/embed/)})
    raise StandardError, "Invalid YouTube URL" if url[2].nil?

    id = url[2].split(/[^a-zA-Z0-9_-]/i) # tweak this to allow for time, fix youtube_tag_spec
    id[0]
  end

  def translate_start_time(id)
    time_in_seconds = id.split("?t=")[-1]
    "#{id.split('?t=')[0]}?start=#{time_in_seconds}"
  end

  def valid_id?(id)
    id =~ /[a-zA-Z0-9_-]{11}((\?t=)?(\d{1,})?)/
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)

UnifiedEmbed.register(YoutubeTag, regexp: YoutubeTag::YOUTUBE_URL_REGEX)
