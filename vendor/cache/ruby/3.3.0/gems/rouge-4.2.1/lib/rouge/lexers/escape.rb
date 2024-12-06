# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Escape < Lexer
      tag 'escape'
      aliases 'esc'

      desc 'A generic lexer for including escaped content - see Formatter.enable_escape!'

      option :start, 'the beginning of the escaped section, default "<!"'
      option :end, 'the end of the escaped section, e.g. "!>"'
      option :lang, 'the language to lex in unescaped sections'

      attr_reader :start
      attr_reader :end
      attr_reader :lang

      def initialize(*)
        super
        @start = string_option(:start) { '<!' }
        @end = string_option(:end) { '!>' }
        @lang = lexer_option(:lang) { PlainText.new }
      end

      def to_start_regex
        @to_start_regex ||= /(.*?)(#{Regexp.escape(@start)})/m
      end

      def to_end_regex
        @to_end_regex ||= /(.*?)(#{Regexp.escape(@end)})/m
      end

      def stream_tokens(str, &b)
        stream = StringScanner.new(str)

        loop do
          if stream.scan(to_start_regex)
            puts "pre-escape: #{stream[1].inspect}" if @debug
            @lang.continue_lex(stream[1], &b)
          else
            # no more start delimiters, scan til the end
            @lang.continue_lex(stream.rest, &b)
            return
          end

          if stream.scan(to_end_regex)
            yield Token::Tokens::Escape, stream[1]
          else
            yield Token::Tokens::Escape, stream.rest
            return
          end
        end
      end
    end
  end
end
