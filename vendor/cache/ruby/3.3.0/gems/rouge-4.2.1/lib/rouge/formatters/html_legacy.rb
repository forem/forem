# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# stdlib
require 'cgi'

module Rouge
  module Formatters
    # Transforms a token stream into HTML output.
    class HTMLLegacy < Formatter
      tag 'html_legacy'

      # @option opts [String] :css_class ('highlight')
      # @option opts [true/false] :line_numbers (false)
      # @option opts [Rouge::CSSTheme] :inline_theme (nil)
      # @option opts [true/false] :wrap (true)
      #
      # Initialize with options.
      #
      # If `:inline_theme` is given, then instead of rendering the
      # tokens as <span> tags with CSS classes, the styles according to
      # the given theme will be inlined in "style" attributes.  This is
      # useful for formats in which stylesheets are not available.
      #
      # Content will be wrapped in a tag (`div` if tableized, `pre` if
      # not) with the given `:css_class` unless `:wrap` is set to `false`.
      def initialize(opts={})
        @formatter = opts[:inline_theme] ? HTMLInline.new(opts[:inline_theme])
                   : HTML.new


        @formatter = HTMLTable.new(@formatter, opts) if opts[:line_numbers]

        if opts.fetch(:wrap, true)
          @formatter = HTMLPygments.new(@formatter, opts.fetch(:css_class, 'codehilite'))
        end
      end

      # @yield the html output.
      def stream(tokens, &b)
        @formatter.stream(tokens, &b)
      end
    end
  end
end
