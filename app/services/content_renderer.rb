class ContentRenderer
  class_attribute :fixer, default: MarkdownProcessor::Fixer::FixAll
  class_attribute :parser, default: FrontMatterParser::Parser.new(:md)

  delegate :calculate_reading_time, :finalize, to: :processed
  delegate :content, :front_matter, to: :parsed_input

  attr_reader :input, :source, :user

  def initialize(input = "", source:, user:)
    @input = input
    @source = source
    @user = user
  end

  def processed
    @processed ||= MarkdownProcessor::Parser.new(content, source: source, user: user)
  end

  private

  def fix(markdown)
    fixer.call(markdown)
  end

  def parse(markdown)
    parser.call(markdown)
  end

  def parsed_input
    @parsed_input = parse(fix(input))
  end
end
