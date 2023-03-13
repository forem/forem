# Render markdown, like ContentRenderer, but without frontmatter (Comments, DisplayAds)
class BasicContentRenderer
  class_attribute :processor, default: MarkdownProcessor::Parser

  class ContentParsingError < StandardError
  end

  def initialize(input, source:, user: nil, fixer: MarkdownProcessor::Fixer::FixAll)
    @input = input || ""
    @source = source
    @user = user
    @fixer = fixer
  end

  def process(link_attributes: {}, sanitize_options: {},
              prefix_images_options: { width: 800, synchronous_detail_detection: false })
    fixed = fixer.call(input)
    processed = processor.new(fixed, source: source, user: user)
    processed.finalize(link_attributes: link_attributes,
                       sanitize_options: sanitize_options,
                       prefix_images_options: prefix_images_options)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  private

  attr_reader :fixer, :input, :user, :source
end
