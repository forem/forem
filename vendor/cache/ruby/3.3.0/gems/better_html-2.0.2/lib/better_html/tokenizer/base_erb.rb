# frozen_string_literal: true

require "erubi"
require_relative "token"
require_relative "location"
require "parser/source/buffer"

module BetterHtml
  module Tokenizer
    class BaseErb < ::Erubi::Engine
      REGEXP_WITHOUT_TRIM = /<%(={1,2})?(.*?)()?%>([ \t]*\r?\n)?/m
      STMT_TRIM_MATCHER = /\A(-|#)?(.*?)([-=])?\z/m
      EXPR_TRIM_MATCHER = /\A(.*?)(-)?\z/m

      attr_reader :tokens
      attr_reader :current_position

      def initialize(buffer)
        raise ArgumentError,
          "first argument must be Parser::Source::Buffer" unless buffer.is_a?(::Parser::Source::Buffer)

        @buffer = buffer
        @tokens = []
        @current_position = 0
        super(buffer.source, regexp: REGEXP_WITHOUT_TRIM, trim: false)
      end

      private

      def append(text)
        @current_position += text.length
      end

      def add_code(code)
        if code[0] == "%"
          add_erb_tokens(nil, "%", code[1..-1], nil)
          append("<%#{code}%>")
        else
          _, ltrim_or_comment, code, rtrim = *STMT_TRIM_MATCHER.match(code)
          ltrim = ltrim_or_comment if ltrim_or_comment == "-"
          indicator = ltrim_or_comment if ltrim_or_comment == "#"
          add_erb_tokens(ltrim, indicator, code, rtrim)
          append("<%#{ltrim}#{indicator}#{code}#{rtrim}%>")
        end
      end

      def add_expression(indicator, code)
        _, code, rtrim = *EXPR_TRIM_MATCHER.match(code)
        add_erb_tokens(nil, indicator, code, rtrim)
        append("<%#{indicator}#{code}#{rtrim}%>")
      end

      def add_erb_tokens(ltrim, indicator, code, rtrim)
        pos = current_position

        add_token(:erb_begin, pos, pos + 2)
        pos += 2

        if ltrim
          add_token(:trim, pos, pos + ltrim.length)
          pos += ltrim.length
        end

        if indicator
          add_token(:indicator, pos, pos + indicator.length)
          pos += indicator.length
        end

        add_token(:code, pos, pos + code.length)
        pos += code.length

        if rtrim
          add_token(:trim, pos, pos + rtrim.length)
          pos += rtrim.length
        end

        add_token(:erb_end, pos, pos + 2)
      end

      def add_token(type, begin_pos, end_pos)
        token = Token.new(
          type: type,
          loc: Location.new(@buffer, begin_pos, end_pos)
        )
        @tokens << token
        token
      end
    end
  end
end
