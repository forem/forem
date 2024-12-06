# frozen_string_literal: true

require_relative 'base_formatter'

module AmazingPrint
  module Formatters
    class ClassFormatter < BaseFormatter
      attr_reader :klass, :inspector, :options

      def initialize(klass, inspector)
        super()
        @klass = klass
        @inspector = inspector
        @options = inspector.options
      end

      def format
        superclass = klass.superclass
        if superclass
          colorize("#{klass.inspect} < #{superclass}", :class)
        else
          colorize(klass.inspect, :class)
        end
      end
    end
  end
end
