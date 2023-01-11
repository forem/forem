class ContentRenderer
  class_attribute :fixer, default: MarkdownProcessor::Fixer::FixAll
  class_attribute :front_matter_parser, default: FrontMatterParser::Parser.new(:md)
  class_attribute :processor, default: MarkdownProcessor::Parser

  class ContentParsingError < StandardError
  end

  delegate :calculate_reading_time, to: :processed
  delegate :content, :front_matter, to: :parsed_input

  attr_reader :input, :source, :user

  def initialize(input, source:, user:)
    @input = input || ""
    @source = source
    @user = user
  end

  def processed
    @processed ||= processor.new(content, source: source, user: user)
  # TODO: Replicating prior behaviour, but this swallows errors we probably shouldn't
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  def finalize(link_attributes: {})
    processed.finalize(link_attributes: link_attributes)
  # TODO: Replicating prior behaviour, but this swallows errors we probably shouldn't
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  private

  def fix(markdown)
    fixer.call(markdown)
  # TODO: Replicating prior behaviour, but this swallows errors we probably shouldn't
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  def parse_front_matter(markdown)
    front_matter_parser.call(markdown)
  # TODO: Replicating prior behaviour, but this swallows errors we probably shouldn't
  rescue StandardError => e
    raise ContentParsingError, e.message
  end

  def parsed_input
    @parsed_input = parse_front_matter(fix(input))
  # TODO: Replicating prior behaviour, but this swallows errors we probably shouldn't
  rescue StandardError => e
    raise ContentParsingError, e.message
  end
end
