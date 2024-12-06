# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    # Transforms a token stream into HTML output.
    class HTML < Formatter
      TABLE_FOR_ESCAPE_HTML = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
      }.freeze

      ESCAPE_REGEX = /[&<>]/.freeze

      tag 'html'

      # @yield the html output.
      def stream(tokens, &b)
        tokens.each { |tok, val| yield span(tok, val) }
      end

      def span(tok, val)
        return val if escape?(tok)

        safe_span(tok, escape_special_html_chars(val))
      end

      def safe_span(tok, safe_val)
        if tok == Token::Tokens::Text
          safe_val
        else
          shortname = tok.shortname or raise "unknown token: #{tok.inspect} for #{safe_val.inspect}"

          "<span class=\"#{shortname}\">#{safe_val}</span>"
        end
      end

      private

      # A performance-oriented helper method to escape `&`, `<` and `>` for the rendered
      # HTML from this formatter.
      #
      # `String#gsub` will always return a new string instance irrespective of whether
      # a substitution occurs. This method however invokes `String#gsub` only if
      # a substitution is imminent.
      #
      # Returns either the given `value` argument string as is or a new string with the
      # special characters replaced with their escaped counterparts.
      def escape_special_html_chars(value)
        return value unless value =~ ESCAPE_REGEX

        value.gsub(ESCAPE_REGEX, TABLE_FOR_ESCAPE_HTML)
      end
    end
  end
end
