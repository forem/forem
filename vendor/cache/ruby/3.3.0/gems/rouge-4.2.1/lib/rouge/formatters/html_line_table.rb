# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    class HTMLLineTable < Formatter
      tag 'html_line_table'

      # @param [Rouge::Formatters::Formatter] formatter An instance of a
      #   `Rouge::Formatters::HTML` or `Rouge::Formatters::HTMLInline`
      # @param [Hash] opts options for HTMLLineTable instance.
      # @option opts [Integer] :start_line line number to start from. Defaults to `1`.
      # @option opts [String] :table_class Class name for the table.
      #   Defaults to `"rouge-line-table"`.
      # @option opts [String] :line_id  a `sprintf` template for generating an `id`
      #   attribute for each table row corresponding to current line number.
      #   Defaults to `"line-%i"`.
      # @option opts [String] :line_class Class name for each table row.
      #   Defaults to `"lineno"`.
      # @option opts [String] :gutter_class Class name for rendered line-number cell.
      #   Defaults to `"rouge-gutter"`.
      # @option opts [String] :code_class Class name for rendered code cell.
      #   Defaults to `"rouge-code"`.
      def initialize(formatter, opts={})
        @formatter    = formatter
        @start_line   = opts.fetch :start_line,   1
        @table_class  = opts.fetch :table_class,  'rouge-line-table'
        @gutter_class = opts.fetch :gutter_class, 'rouge-gutter'
        @code_class   = opts.fetch :code_class,   'rouge-code'
        @line_class   = opts.fetch :line_class,   'lineno'
        @line_id      = opts.fetch :line_id,      'line-%i'
      end

      def stream(tokens, &b)
        buffer = [%(<table class="#@table_class"><tbody>)]
        token_lines(tokens).with_index(@start_line) do |line_tokens, lineno|
          buffer << %(<tr id="#{sprintf @line_id, lineno}" class="#@line_class">)
          buffer << %(<td class="#@gutter_class gl" )
          buffer << %(style="-moz-user-select: none;-ms-user-select: none;)
          buffer << %(-webkit-user-select: none;user-select: none;">)
          buffer << %(<pre>#{lineno}</pre></td>)
          buffer << %(<td class="#@code_class"><pre>)
          @formatter.stream(line_tokens) { |formatted| buffer << formatted }
          buffer << "\n</pre></td></tr>"
        end
        buffer << %(</tbody></table>)
        yield buffer.join
      end
    end
  end
end
