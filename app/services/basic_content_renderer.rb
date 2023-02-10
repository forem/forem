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

  def process(link_attributes: {}, sanitize_options: {})
    fixed = fixer.call(input)
    processed = processor.new(fixed, source: source, user: user, sanitize_options: sanitize_options)
    processed.finalize(link_attributes: link_attributes)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  private

  attr_reader :fixer, :input, :user, :source
end
