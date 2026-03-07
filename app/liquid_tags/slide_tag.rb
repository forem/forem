class SlideTag < Liquid::Tag
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/slide".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @image = options["image"]
    @alt = options["alt"] || ""
    @title = options["title"]
    @video = options["video"]
    @link = options["link"]
    @video_embed_id = extract_youtube_id(@video) if @video
    raise StandardError, I18n.t("liquid_tags.slide_tag.missing_image") unless @image || @video || @link
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        image: @image,
        alt: @alt,
        title: @title,
        video: @video,
        link: @link,
        video_embed_id: @video_embed_id,
      },
    )
  end

  private

  def parse_options(markup)
    cleaned = strip_tags(markup)
    options = {}
    cleaned.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = (quoted_val || plain_val).strip
    end
    options
  end

  def extract_youtube_id(url)
    if url.match?(%r{youtu\.be/})
      url.split("youtu.be/").last.split(/[?&]/).first
    elsif url.match?(%r{youtube\.com.*[?&]v=})
      url.match(/[?&]v=([^&]+)/)[1]
    end
  end
end

Liquid::Template.register_tag("slide", SlideTag)
