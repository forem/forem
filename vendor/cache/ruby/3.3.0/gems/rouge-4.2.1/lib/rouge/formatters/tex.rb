# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    class Tex < Formatter
      tag 'tex'

      # A map of TeX escape characters.
      # Newlines are handled specially by using #token_lines
      # spaces are preserved as long as they aren't at the beginning
      # of a line. see #tag_first for our initial-space strategy
      ESCAPE = {
        '&' => '\&',
        '%' => '\%',
        '$' => '\$',
        '#' => '\#',
        '_' => '\_',
        '{' => '\{',
        '}' => '\}',
        '~' => '{\textasciitilde}',
        '^' => '{\textasciicircum}',
        '|' => '{\textbar}',
        '\\' => '{\textbackslash}',
        '`' => '{\textasciigrave}',
        "'" => "'{}",
        '"' => '"{}',
        "\t" => '{\tab}',
      }

      ESCAPE_REGEX = /[#{ESCAPE.keys.map(&Regexp.method(:escape)).join}]/om

      def initialize(opts={})
        @prefix = opts.fetch(:prefix) { 'RG' }
      end

      def escape_tex(str)
        str.gsub(ESCAPE_REGEX, ESCAPE)
      end

      def stream(tokens, &b)
        # surround the output with \begin{RG*}...\end{RG*}
        yield "\\begin{#{@prefix}*}%\n"

        # we strip the newline off the last line to avoid
        # an extra line being rendered. we do this by yielding
        # the \newline tag *before* every line group except
        # the first.
        first = true

        token_lines tokens do |line|
          if first
            first = false
          else
            yield "\\newline%\n"
          end

          render_line(line, &b)
        end

        yield "%\n\\end{#{@prefix}*}%\n"
      end

      def render_line(line, &b)
        line.each do |(tok, val)|
          hphantom_tag(tok, val, &b)
        end
      end

      # Special handling for leading spaces, since they may be gobbled
      # by a previous command.  We replace all initial spaces with
      # \hphantom{xxxx}, which renders an empty space equal to the size
      # of the x's.
      def hphantom_tag(tok, val)
        leading = nil
        val.sub!(/^[ ]+/) { leading = $&.size; '' }
        yield "\\hphantom{#{'x' * leading}}" if leading
        yield tag(tok, val) unless val.empty?
      end

      def tag(tok, val)
        if escape?(tok)
          val
        elsif tok == Token::Tokens::Text
          escape_tex(val)
        else
          "\\#@prefix{#{tok.shortname}}{#{escape_tex(val)}}"
        end
      end
    end
  end
end
