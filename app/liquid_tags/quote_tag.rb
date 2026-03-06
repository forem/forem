class QuoteTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/quote".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/
  VALID_RATINGS = (1..5).to_a.freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @author = options["author"]
    @role = options["role"]
    @image = options["image"]
    @rating = parse_rating(options["rating"])
    @source = options["source"]
    @link = options["link"]
    raise StandardError, I18n.t("liquid_tags.quote_tag.missing_author") unless @author
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        author: @author,
        role: @role,
        image: @image,
        rating: @rating,
        source: @source,
        link: @link,
        content: content,
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

  def parse_rating(value)
    return nil unless value

    rating = value.to_i
    raise StandardError, I18n.t("liquid_tags.quote_tag.invalid_rating") unless VALID_RATINGS.include?(rating)

    rating
  end
end

Liquid::Template.register_tag("quote", QuoteTag)
