# frozen_string_literal: true

require 'kramdown'
require 'kramdown-parser-gfm'
require 'yard'
require 'reverse_markdown'
require 'solargraph/converters/dl'
require 'solargraph/converters/dt'
require 'solargraph/converters/dd'
require 'solargraph/converters/misc'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # A documentation formatter that either performs Markdown conversion for
      # text, or applies backticks for code blocks.
      #
      class DocSection
        # @return [String]
        attr_reader :plaintext

        # @param code [Boolean] True if this section is a code block
        def initialize code
          @plaintext = String.new('')
          @code = code
        end

        def code?
          @code
        end

        # @param text [String]
        # @return [String]
        def concat text
          @plaintext.concat text
        end

        def to_s
          return "\n```ruby\n#{@plaintext}#{@plaintext.end_with?("\n") ? '' : "\n"}```\n\n" if code?
          ReverseMarkdown.convert unescape_brackets(Kramdown::Document.new(escape_brackets(@plaintext), input: 'GFM').to_html)
        end

        private

        # @param text [String]
        # @return [String]
        def escape_brackets text
          # text.gsub(/(\[[^\]]*\])([^\(]|\z)/, '!!!^\1^!!!\2')
          text.gsub('[', '!!!!b').gsub(']', 'e!!!!')
        end

        # @param text [String]
        # @return [String]
        def unescape_brackets text
          text.gsub('!!!!b', '[').gsub('e!!!!', ']')
        end
      end

      # @return [String]
      def documentation
        @documentation ||= begin
          # Using DocSections allows for code blocks that start with an empty
          # line and at least two spaces of indentation. This is a common
          # convention in Ruby core documentation, e.g., String#split.
          sections = [DocSection.new(false)]
          normalize_indentation(docstring.to_s).gsub(/\t/, '  ').lines.each do |l|
            if l.strip.empty?
              sections.last.concat l
            else
              if (l =~ /^  [^\s]/ && sections.last.plaintext =~ /(\r?\n[ \t]*?){2,}$/) || (l.start_with?('  ') && sections.last.code?)
                # Code block
                sections.push DocSection.new(true) unless sections.last.code?
                sections.last.concat l[2..-1]
              else
                # Regular documentation
                sections.push DocSection.new(false) if sections.last.code?
                sections.last.concat l
              end
            end
          end
          sections.map(&:to_s).join.strip
        end
      end

      private

      # @param text [String]
      # @return [String]
      def normalize_indentation text
        text.lines.map { |l| remove_odd_spaces(l) }.join
      end

      # @param line [String]
      # @return [String]
      def remove_odd_spaces line
        return line unless line.start_with?(' ')
        spaces = line.match(/^ +/)[0].length
        return line unless spaces.odd?
        line[1..-1]
      end
    end
  end
end
