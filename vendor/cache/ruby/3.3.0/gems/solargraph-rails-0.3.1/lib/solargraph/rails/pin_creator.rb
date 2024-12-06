# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module Solargraph
  module Rails
    class PinCreator
      attr_reader :contents, :path

      def initialize(path, contents)
        @path = path
        @contents = contents
      end

      def create_pins
        model_attrs = []
        model_name = nil
        module_names = []
        parser = RubyParser.new(file_contents: contents)

        parser.on_comment do |comment|
          Solargraph::Logging.logger.info "found comment #{comment}"
          col_name, col_type = col_with_type(comment)
          if type_translation.keys.include?(col_type)
            loc = Solargraph::Location.new(
              path,
              Solargraph::Range.from_to(
                parser.current_line_number,
                0,
                parser.current_line_number,
                parser.current_line_length - 1
              )
            )
            model_attrs << { name: col_name, type: col_type, location: loc }
          else
            Solargraph::Logging.logger.info 'could not find annotation in comment'
          end
        end

        parser.on_module do |mod_name|
          Solargraph::Logging.logger.info "found module #{mod_name}"
          module_names << mod_name
        end

        parser.on_class do |klass, superklass|
          Solargraph::Logging.logger.info "found class: #{klass} < #{superklass}"
          if ['ActiveRecord::Base', 'ApplicationRecord'].include?(superklass)
            model_name = klass
          else
            Solargraph::Logging.logger.info "Unable to find ActiveRecord model from #{klass} #{superklass}"
            model_attrs = [] # don't include anything from this file
          end
        end

        parser.on_ruby_line do |line|
          matcher = ruby_matchers.find do |m|
            m.match?(line)
          end

          if matcher
            loc = Solargraph::Location.new(
              path,
              Solargraph::Range.from_to(
                parser.current_line_number,
                0,
                parser.current_line_number,
                parser.current_line_length - 1
              )
            )
            model_attrs << { name: matcher.name, type: matcher.type, location: loc }
          end
        end

        parser.parse

        Solargraph::Logging.logger.info "Adding #{model_attrs.count} attributes as pins"
        model_attrs.map do |attr|
          Solargraph::Pin::Method.new(
            name: attr[:name],
            comments: "@return [#{type_translation.fetch(attr[:type], attr[:type])}]",
            location: attr[:location],
            closure: Solargraph::Pin::Namespace.new(name: module_names.join('::') + "::#{model_name}"),
            scope: :instance,
            attribute: true
          )
        end
      end

      def ruby_matchers
        [
          MetaSource::Association::BelongsToMatcher.new,
          MetaSource::Association::HasManyMatcher.new,
          MetaSource::Association::HasOneMatcher.new,
          MetaSource::Association::HasAndBelongsToManyMatcher.new
        ]
      end
      def col_with_type(line)
        line
          .gsub(/[\(\),:\d]/, '')
          .split
          .first(2)
      end

      def type_translation
        {
          'decimal' => 'BigDecimal',
          'integer' => 'Integer',
          'date' => 'Date',
          'datetime' => 'ActiveSupport::TimeWithZone',
          'string' => 'String',
          'boolean' => 'Boolean',
          'float' => 'Float',
          'text' => 'String'
        }
      end
    end
  end
end
