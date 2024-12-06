# frozen_string_literal: true

require_relative 'base_formatter'

module AmazingPrint
  module Formatters
    class SimpleFormatter < BaseFormatter
      attr_reader :string, :type, :inspector, :options

      def initialize(string, type, inspector)
        super()
        @string = string
        @type = type
        @inspector = inspector
        @options = inspector.options
      end

      def format
        colorize(string, type)
      end
    end
  end
end
