# frozen_string_literal: true

require_relative 'base_formatter'

module AmazingPrint
  module Formatters
    class HashFormatter < BaseFormatter
      attr_reader :hash, :inspector, :options

      def initialize(hash, inspector)
        super()
        @hash = hash
        @inspector = inspector
        @options = inspector.options
      end

      def format
        if hash.empty?
          empty_hash
        elsif multiline_hash?
          multiline_hash
        else
          simple_hash
        end
      end

      private

      def empty_hash
        '{}'
      end

      def multiline_hash?
        options[:multiline]
      end

      def multiline_hash
        ["{\n", printable_hash.join(",\n"), "\n#{outdent}}"].join
      end

      def simple_hash
        "{ #{printable_hash.join(', ')} }"
      end

      def printable_hash
        data = printable_keys
        width = left_width(data)

        data.map! do |key, value|
          indented do
            if options[:ruby19_syntax] && symbol?(key)
              ruby19_syntax(key, value, width)
            else
              pre_ruby19_syntax(key, value, width)
            end
          end
        end

        should_be_limited? ? limited(data, width, is_hash: true) : data
      end

      def left_width(keys)
        result = max_key_width(keys)
        result += indentation if options[:indent].positive?
        result
      end

      def max_key_width(keys)
        keys.map { |key, _value| colorless_size(key) }.max || 0
      end

      def printable_keys
        keys = hash.keys

        keys.sort! { |a, b| a.to_s <=> b.to_s } if options[:sort_keys]

        keys.map! do |key|
          plain_single_line do
            [inspector.awesome(key), hash[key]]
          end
        end
      end

      def symbol?(key)
        key[0] == ':'
      end

      def ruby19_syntax(key, value, width)
        key[0] = ''
        key << ':'
        "#{align(key, width)} #{inspector.awesome(value)}"
      end

      def pre_ruby19_syntax(key, value, width)
        "#{align(key, width)}#{colorize(' => ', :hash)}#{inspector.awesome(value)}"
      end

      def plain_single_line
        multiline = options[:multiline]
        options[:multiline] = false
        yield
      ensure
        options[:multiline] = multiline
      end
    end
  end
end
