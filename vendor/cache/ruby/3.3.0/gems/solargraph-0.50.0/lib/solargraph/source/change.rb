# frozen_string_literal: true

module Solargraph
  class Source
    # A change to be applied to text.
    #
    class Change
      include EncodingFixes

      # @return [Range]
      attr_reader :range

      # @return [String]
      attr_reader :new_text

      # @param range [Range] The starting and ending positions of the change.
      #   If nil, the original text will be overwritten.
      # @param new_text [String] The text to be changed.
      def initialize range, new_text
        @range = range
        @new_text = new_text
      end

      # Write the change to the specified text.
      #
      # @param text [String] The text to be changed.
      # @param nullable [Boolean] If true, minor changes that could generate
      #   syntax errors will be repaired.
      # @return [String] The updated text.
      def write text, nullable = false
        if nullable and !range.nil? and new_text.match(/[\.\[\{\(@\$:]$/)
          [':', '@'].each do |dupable|
            next unless new_text == dupable
            offset = Position.to_offset(text, range.start)
            if text[offset - 1] == dupable
              p = Position.from_offset(text, offset - 1)
              r = Change.new(Range.new(p, range.start), ' ')
              text = r.write(text)
            end
            break
          end
          commit text, "#{new_text[0..-2]} "
        elsif range.nil?
          new_text
        else
          commit text, new_text
        end
      end

      # Repair an update by replacing the new text with similarly formatted
      # whitespace.
      #
      # @param text [String] The text to be changed.
      # @return [String] The updated text.
      def repair text
        fixed = new_text.gsub(/[^\s]/, ' ')
        if range.nil?
          fixed
        else
          result = commit text, fixed
          off = Position.to_offset(text, range.start)
          match = result[0, off].match(/[\.:]+\z/)
          if match
            result = result[0, off].sub(/#{match[0]}\z/, ' ' * match[0].length) + result[off..-1]
          end
          result
        end
      end

      private

      def commit text, insert
        start_offset = Position.to_offset(text, range.start)
        end_offset = Position.to_offset(text, range.ending)
        (start_offset == 0 ? '' : text[0..start_offset-1].to_s) + normalize(insert) + text[end_offset..-1].to_s
      end
    end
  end
end
