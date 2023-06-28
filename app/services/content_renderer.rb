# renders markdown for Articles, DisplayAds, Comments
class ContentRenderer
  Result = Struct.new(:front_matter, :reading_time, :processed_html, keyword_init: true)

  class_attribute :processor, default: MarkdownProcessor::Parser
  class_attribute :front_matter_parser, default: FrontMatterParser::Parser.new(:md)

  class ContentParsingError < StandardError
  end

  # @param input [String] body_markdown to process
  # @param source [Article, Comment, DisplayAd]
  # @param user [User, NilClass] article's or comment's user, nil for DisplayAd
  # @param fixer [Object] fixes the input markdown
  def initialize(input, source:, user: nil, fixer: MarkdownProcessor::Fixer::FixAll)
    @input = input || ""
    @source = source
    @user = user
    @fixer = fixer
  end

  # @param link_attributes [Hash] options passed further to RedCarpet::Render::HTMLRouge, example: { rel: "nofollow"}
  # @param prefix_images_options [Hash] options for Html::Parser#prefix_all_images
  # @return [ContentRenderer::Result]
  def process(link_attributes: {},
              prefix_images_options: { width: 800, synchronous_detail_detection: false })
    fixed = fixer.call(input)
    processed = processor.new(fixed, source: source, user: user)

    processed_html = processed.finalize(link_attributes: link_attributes,
                                        prefix_images_options: prefix_images_options)

    Result.new(front_matter: nil, processed_html: processed_html, reading_time: 0)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  # processes Article markdown, calculates reading time and finds frontmatter (if it exists)
  #
  # @return [ContentRenderer::Result]
  def process_article
    fixed = fixer.call(input)
    parsed = front_matter_parser.call(fixed)
    front_matter = parsed.front_matter
    processed = processor.new(parsed.content, source: source, user: user)

    reading_time = processed.calculate_reading_time

    processed_html = processed.finalize

    Result.new(front_matter: front_matter, processed_html: processed_html, reading_time: reading_time)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  def has_front_matter?
    fixed = fixer.call(input)
    parsed = front_matter_parser.call(fixed)
    front_matter = parsed.front_matter
    front_matter.any? && front_matter["title"].present?
  rescue ContentRenderer::ContentParsingError
    true
  end

  private

  attr_reader :fixer, :input, :user, :source
end
