# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    class HTMLLineHighlighter < Formatter
      tag 'html_line_highlighter'

      def initialize(delegate, opts = {})
        @delegate = delegate
        @highlight_line_class = opts.fetch(:highlight_line_class, 'hll')
        @highlight_lines = opts[:highlight_lines] || []
      end

      def stream(tokens)
        token_lines(tokens).with_index(1) do |line_tokens, lineno|
          line = %(#{@delegate.format(line_tokens)}\n)
          line = %(<span class="#{@highlight_line_class}">#{line}</span>) if @highlight_lines.include? lineno
          yield line
        end
      end
    end
  end
end
