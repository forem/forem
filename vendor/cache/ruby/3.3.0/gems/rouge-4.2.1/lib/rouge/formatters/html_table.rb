# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    class HTMLTable < Formatter
      tag 'html_table'

      def initialize(inner, opts={})
        @inner = inner
        @start_line = opts.fetch(:start_line, 1)
        @line_format = opts.fetch(:line_format, '%i')
        @table_class = opts.fetch(:table_class, 'rouge-table')
        @gutter_class = opts.fetch(:gutter_class, 'rouge-gutter')
        @code_class = opts.fetch(:code_class, 'rouge-code')
      end

      def style(scope)
        yield %(#{scope} .rouge-table { border-spacing: 0 })
        yield %(#{scope} .rouge-gutter { text-align: right })
      end

      def stream(tokens, &b)
        last_val = nil
        num_lines = tokens.reduce(0) {|count, (_, val)| count + (last_val = val).count(?\n) }
        formatted = @inner.format(tokens)
        unless last_val && last_val.end_with?(?\n)
          num_lines += 1
          formatted << ?\n
        end

        # generate a string of newline-separated line numbers for the gutter>
        formatted_line_numbers = (@start_line..(@start_line + num_lines - 1)).map do |i|
          sprintf(@line_format, i)
        end.join(?\n) << ?\n

        buffer = [%(<table class="#@table_class"><tbody><tr>)]
        # the "gl" class applies the style for Generic.Lineno
        buffer << %(<td class="#@gutter_class gl">)
        buffer << %(<pre class="lineno">#{formatted_line_numbers}</pre>)
        buffer << '</td>'
        buffer << %(<td class="#@code_class"><pre>)
        buffer << formatted
        buffer << '</pre></td>'
        buffer << '</tr></tbody></table>'

        yield buffer.join
      end
    end
  end
end
