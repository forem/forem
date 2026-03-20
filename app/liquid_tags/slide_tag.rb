class SlideTag < Liquid::Tag
  include ActionView::Helpers::SanitizeHelper
  include LiquidTagHelpers

  PARTIAL = "liquids/slide".freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @image = options["image"]
    @alt = options["alt"] || ""
    @title = options["title"]
    @video = options["video"]
    @link = options["link"]
    @video_embed_id = YoutubeTag.extract_video_id(@video) if @video
    validate_url!(@image, "image")
    validate_url!(@video, "video")
    validate_url!(@link, "link")
    raise StandardError, I18n.t("liquid_tags.slide_tag.missing_content") unless @image || @video || @link
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
end

Liquid::Template.register_tag("slide", SlideTag)
