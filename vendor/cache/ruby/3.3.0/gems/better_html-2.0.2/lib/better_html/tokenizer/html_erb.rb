# frozen_string_literal: true

require_relative "base_erb"

module BetterHtml
  module Tokenizer
    class HtmlErb < BaseErb
      attr_reader :parser

      def initialize(buffer)
        @parser = HtmlTokenizer::Parser.new
        super(buffer)
      end

      def current_position
        @parser.document_length
      end

      private

      def append(text)
        @parser.append_placeholder(text)
      end

      def add_text(text)
        @parser.parse(text) do |type, begin_pos, end_pos, _line, _column|
          add_token(type, begin_pos, end_pos)
        end
      end
    end
  end
end
