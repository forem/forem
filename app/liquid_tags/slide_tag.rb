class SlideTag < Liquid::Tag
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/slide".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @image = options["image"]
    @alt = options["alt"] || ""
    @video = options["video"]
    raise StandardError, I18n.t("liquid_tags.slide_tag.missing_image") unless @image
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        image: @image,
        alt: @alt,
        video: @video,
      },
    )
  end

  private

  def parse_options(markup)
    options = {}
    markup.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = quoted_val || plain_val
    end
    options
  end
end

Liquid::Template.register_tag("slide", SlideTag)
