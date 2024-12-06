# frozen_string_literal: true

require 'capybara/selector/selector'

module Capybara
  class Selector
    class CSS
      def self.escape(str)
        value = str.dup
        out = +''
        out << value.slice!(0...1) if value.match?(/^[-_]/)
        out << (value[0].match?(NMSTART) ? value.slice!(0...1) : escape_char(value.slice!(0...1)))
        out << value.gsub(/[^a-zA-Z0-9_-]/) { |char| escape_char char }
        out
      end

      def self.escape_char(char)
        char.match?(%r{[ -/:-~]}) ? "\\#{char}" : format('\\%06<hex>x', hex: char.ord)
      end

      def self.split(css)
        Splitter.new.split(css)
      end

      S = '\u{80}-\u{D7FF}\u{E000}-\u{FFFD}\u{10000}-\u{10FFFF}'
      H = /[0-9a-fA-F]/.freeze
      UNICODE  = /\\#{H}{1,6}[ \t\r\n\f]?/.freeze
      NONASCII = /[#{S}]/.freeze
      ESCAPE   = /#{UNICODE}|\\[ -~#{S}]/.freeze
      NMSTART = /[_a-zA-Z]|#{NONASCII}|#{ESCAPE}/.freeze

      class Splitter
        def split(css)
          selectors = []
          StringIO.open(css.to_s) do |str|
            selector = +''
            while (char = str.getc)
              case char
              when '['
                selector << parse_square(str)
              when '('
                selector << parse_paren(str)
              when '"', "'"
                selector << parse_string(char, str)
              when '\\'
                selector << (char + str.getc)
              when ','
                selectors << selector.strip
                selector.clear
              else
                selector << char
              end
            end
            selectors << selector.strip
          end
          selectors
        end

      private

        def parse_square(strio)
          parse_block('[', ']', strio)
        end

        def parse_paren(strio)
          parse_block('(', ')', strio)
        end

        def parse_block(start, final, strio)
          block = start
          while (char = strio.getc)
            case char
            when final
              return block + char
            when '\\'
              block += char + strio.getc
            when '"', "'"
              block += parse_string(char, strio)
            else
              block += char
            end
          end
          raise ArgumentError, "Invalid CSS Selector - Block end '#{final}' not found"
        end

        def parse_string(quote, strio)
          string = quote
          while (char = strio.getc)
            string += char
            case char
            when quote
              return string
            when '\\'
              string += strio.getc
            end
          end
          raise ArgumentError, 'Invalid CSS Selector - string end not found'
        end
      end
    end
  end
end
