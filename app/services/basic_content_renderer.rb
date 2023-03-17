# Render markdown, like ContentRenderer, but without frontmatter (Comments, DisplayAds)
class BasicContentRenderer
  Result = Struct.new(:front_matter, :reading_time, :processed_html, keyword_init: true)

  class_attribute :processor, default: MarkdownProcessor::Parser

  class ContentParsingError < StandardError
  end

  def initialize(input, source:, user: nil, fixer: MarkdownProcessor::Fixer::FixAll)
    @input = input || ""
    @source = source
    @user = user
    @fixer = fixer
  end

  def process(calculate_reading_time: false, link_attributes: {}, sanitize_options: {},
              prefix_images_options: { width: 800, synchronous_detail_detection: false })
    fixed = fixer.call(input)

    parsed = FrontMatterParser::Parser.new(:md).call(fixed)
    front_matter = parsed.front_matter

    processed = processor.new(fixed, source: source, user: user)

    reading_time = calculate_reading_time ? processed.calculate_reading_time : 0

    processed_html = processed.finalize(link_attributes: link_attributes,
                                        sanitize_options: sanitize_options,
                                        prefix_images_options: prefix_images_options)

    Result.new(front_matter: front_matter, processed_html: processed_html, reading_time: reading_time)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  private

  attr_reader :fixer, :input, :user, :source
end
