class ContentRenderer
  attr_accessor :fixed_markdown, :parsed, :processed_markdown

  delegate :front_matter, to: :parsed
  delegate :calculate_reading_time, :finalize, to: :processed_markdown

  def initialize(markdown, source:, user:)
    self.fixed_markdown = MarkdownProcessor::Fixer::FixAll.call(markdown || "")
    self.parsed = FrontMatterParser::Parser.new(:md).call(fixed_markdown)
    self.processed_markdown = MarkdownProcessor::Parser.new(parsed.content, source: source, user: user)
  end
end
