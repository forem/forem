# frozen_string_literal: true

module ERBLint
  class ProcessedSource
    attr_reader :filename, :file_content, :parser

    def initialize(filename, file_content)
      @filename = filename
      @file_content = file_content
      @parser = BetterHtml::Parser.new(source_buffer, template_language: :html)
    end

    def ast
      @parser.ast
    end

    def source_buffer
      @source_buffer ||= begin
        buffer = Parser::Source::Buffer.new(filename)
        buffer.source = file_content
        buffer
      end
    end

    def to_source_range(range)
      range = (range.begin_pos...range.end_pos) if range.is_a?(::Parser::Source::Range)
      BetterHtml::Tokenizer::Location.new(
        source_buffer,
        range.begin,
        range.exclude_end? ? range.end : range.end + 1
      )
    end
  end
end
