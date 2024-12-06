# frozen_string_literal: true

require "anyway/option_parser_builder"

require "anyway/ext/deep_dup"

module Anyway
  using Anyway::Ext::DeepDup

  # Adds ability to use script options as the source
  # of configuration (via optparse)
  module OptparseConfig
    module ClassMethods
      def ignore_options(*args)
        args.each do |name|
          option_parser_descriptors[name.to_s][:ignore] = true
        end
      end

      def describe_options(**hargs)
        hargs.each do |name, desc|
          if String === desc
            option_parser_descriptors[name.to_s][:desc] = desc
          else
            option_parser_descriptors[name.to_s].merge!(desc)
          end
        end
      end

      def flag_options(*args)
        args.each do |name|
          option_parser_descriptors[name.to_s][:flag] = true
        end
      end

      def extend_options(&block)
        option_parser_extensions << block
      end

      def option_parser_options
        config_attributes.each_with_object({}) do |key, result|
          descriptor = option_parser_descriptors[key.to_s]
          next if descriptor[:ignore] == true

          result[key] = descriptor
        end
      end

      def option_parser_extensions
        return @option_parser_extensions if instance_variable_defined?(:@option_parser_extensions)

        @option_parser_extensions =
          if superclass < Anyway::Config
            superclass.option_parser_extensions.dup
          else
            []
          end
      end

      def option_parser_descriptors
        return @option_parser_descriptors if instance_variable_defined?(:@option_parser_descriptors)

        @option_parser_descriptors =
          if superclass < Anyway::Config
            superclass.option_parser_descriptors.deep_dup
          else
            Hash.new { |h, k| h[k] = {} }
          end
      end
    end

    def option_parser
      @option_parser ||= OptionParserBuilder.call(self.class.option_parser_options) do |key, val|
                           write_config_attr(key, val)
                         end.tap do |parser|
        self.class.option_parser_extensions.map do |extension|
          extension.call(parser, self)
        end
      end
    end

    def parse_options!(options)
      Tracing.with_trace_source(type: :options) do
        option_parser.parse!(options)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
