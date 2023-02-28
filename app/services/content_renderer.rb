class ContentRenderer
  class_attribute :fixer, default: MarkdownProcessor::Fixer::FixAll
  class_attribute :front_matter_parser, default: FrontMatterParser::Parser.new(:md)
  class_attribute :processor, default: MarkdownProcessor::Parser

  class ContentParsingError < StandardError
  end

  attr_reader :input, :source, :user
  attr_accessor :reading_time, :front_matter

  def initialize(input, source:, user:)
    @input = input || ""
    @source = source
    @user = user
  end

  def process(link_attributes: {}, calculate_reading_time: false)
    fixed = fixer.call(input)
    parsed = front_matter_parser.call(fixed)
    self.front_matter = parsed.front_matter
    processed = processor.new(parsed.content, source: source, user: user)
    self.reading_time = processed.calculate_reading_time if calculate_reading_time
    processed.finalize(link_attributes: link_attributes)
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  def has_front_matter?
    fixed = fixer.call(input)
    parsed = front_matter_parser.call(fixed)
    self.front_matter = parsed.front_matter
    front_matter.any? && front_matter["title"].present?
  rescue ContentRenderer::ContentParsingError
    true
  end
end
