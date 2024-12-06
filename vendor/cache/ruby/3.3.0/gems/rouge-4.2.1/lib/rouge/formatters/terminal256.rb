# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    # A formatter for 256-color terminals
    class Terminal256 < Formatter
      tag 'terminal256'

      # @private
      attr_reader :theme

      # @param [Hash,Rouge::Theme] theme
      #   the theme to render with.
      def initialize(theme = Themes::ThankfulEyes.new)
        if theme.is_a?(Rouge::Theme)
          @theme = theme
        elsif theme.is_a?(Hash)
          @theme = theme[:theme] || Themes::ThankfulEyes.new
        else
          raise ArgumentError, "invalid theme: #{theme.inspect}"
        end
      end

      def stream(tokens, &b)
        tokens.each do |tok, val|
          escape_sequence(tok).stream_value(val, &b)
        end
      end

      class EscapeSequence
        attr_reader :style
        def initialize(style)
          @style = style
        end

        def self.xterm_colors
          @xterm_colors ||= [].tap do |out|
            # colors 0..15: 16 basic colors
            out << [0x00, 0x00, 0x00] # 0
            out << [0xcd, 0x00, 0x00] # 1
            out << [0x00, 0xcd, 0x00] # 2
            out << [0xcd, 0xcd, 0x00] # 3
            out << [0x00, 0x00, 0xee] # 4
            out << [0xcd, 0x00, 0xcd] # 5
            out << [0x00, 0xcd, 0xcd] # 6
            out << [0xe5, 0xe5, 0xe5] # 7
            out << [0x7f, 0x7f, 0x7f] # 8
            out << [0xff, 0x00, 0x00] # 9
            out << [0x00, 0xff, 0x00] # 10
            out << [0xff, 0xff, 0x00] # 11
            out << [0x5c, 0x5c, 0xff] # 12
            out << [0xff, 0x00, 0xff] # 13
            out << [0x00, 0xff, 0xff] # 14
            out << [0xff, 0xff, 0xff] # 15

            # colors 16..232: the 6x6x6 color cube
            valuerange = [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]

            217.times do |i|
              r = valuerange[(i / 36) % 6]
              g = valuerange[(i / 6) % 6]
              b = valuerange[i % 6]
              out << [r, g, b]
            end

            # colors 233..253: grayscale
            1.upto 22 do |i|
              v = 8 + i * 10
              out << [v, v, v]
            end
          end
        end

        def fg
          return @fg if instance_variable_defined? :@fg
          @fg = style.fg && self.class.color_index(style.fg)
        end

        def bg
          return @bg if instance_variable_defined? :@bg
          @bg = style.bg && self.class.color_index(style.bg)
        end


        def stream_value(val, &b)
          yield style_string
          yield val.gsub("\e", "\\e")
                   .gsub("\n", "#{reset_string}\n#{style_string}")
          yield reset_string
        end

        def style_string
          @style_string ||= begin
            attrs = []

            attrs << ['38', '5', fg.to_s] if fg
            attrs << ['48', '5', bg.to_s] if bg
            attrs << '01' if style[:bold]
            attrs << '04' if style[:italic] # underline, but hey, whatevs
            escape(attrs)
          end
        end

        def reset_string
          @reset_string ||= begin
            attrs = []
            attrs << '39' if fg # fg reset
            attrs << '49' if bg # bg reset
            attrs << '00' if style[:bold] || style[:italic]

            escape(attrs)
          end
        end

      private
        def escape(attrs)
          return '' if attrs.empty?
          "\e[#{attrs.join(';')}m"
        end

        def self.color_index(color)
          @color_index_cache ||= {}
          @color_index_cache[color] ||= closest_color(*get_rgb(color))
        end

        def self.get_rgb(color)
          color = $1 if color =~ /#([0-9a-f]+)/i
          hexes = case color.size
          when 3
            color.chars.map { |c| "#{c}#{c}" }
          when 6
            color.scan(/../)
          else
            raise "invalid color: #{color}"
          end

          hexes.map { |h| h.to_i(16) }
        end

        # max distance between two colors, #000000 to #ffffff
        MAX_DISTANCE = 257 * 257 * 3

        def self.closest_color(r, g, b)
          @@colors_cache ||= {}
          key = (r << 16) + (g << 8) + b
          @@colors_cache.fetch(key) do
            distance = MAX_DISTANCE

            match = 0

            xterm_colors.each_with_index do |(cr, cg, cb), i|
              d = (r - cr)**2 + (g - cg)**2 + (b - cb)**2
              next if d >= distance

              match = i
              distance = d
            end

            match
          end
        end
      end

      class Unescape < EscapeSequence
        def initialize(*) end
        def style_string(*) '' end
        def reset_string(*) '' end
        def stream_value(val) yield val end
      end

    # private
      def escape_sequence(token)
        return Unescape.new if escape?(token)
        @escape_sequences ||= {}
        @escape_sequences[token.qualname] ||=
          make_escape_sequence(get_style(token))
      end

      def make_escape_sequence(style)
        EscapeSequence.new(style)
      end

      def get_style(token)
        return text_style if token.ancestors.include? Token::Tokens::Text

        theme.get_own_style(token) || text_style
      end

      def text_style
        style = theme.get_style(Token['Text'])
        # don't highlight text backgrounds
        style.delete :bg
        style
      end
    end
  end
end
