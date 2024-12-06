# frozen_string_literal: true

module Solargraph
  class Source
    # Updaters contain changes to be applied to a source. The source applies
    # the update via the Source#synchronize method.
    #
    class Updater
      # @return [String]
      attr_reader :filename

      # @return [Integer]
      attr_reader :version

      # @return [Array<Change>]
      attr_reader :changes

      # @param filename [String] The file to update.
      # @param version [Integer] A version number associated with this update.
      # @param changes [Array<Solargraph::Source::Change>] The changes.
      def initialize filename, version, changes
        @filename = filename
        @version = version
        @changes = changes
        @input = nil
        @did_nullify = nil
        @output = nil
      end

      # @param text [String]
      # @param nullable [Boolean]
      # @return [String]
      def write text, nullable = false
        can_nullify = (nullable and changes.length == 1)
        return @output if @input == text and can_nullify == @did_nullify
        @input = text
        @output = text
        @did_nullify = can_nullify
        changes.each do |ch|
          @output = ch.write(@output, can_nullify)
        end
        @output
      end

      # @return [String]
      def repair text
        changes.each do |ch|
          text = ch.repair(text)
        end
        text
      end
    end
  end
end
