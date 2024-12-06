# frozen_string_literal: true

require_relative 'base_formatter'

module AmazingPrint
  module Formatters
    class ObjectFormatter < BaseFormatter
      attr_reader :object, :variables, :inspector, :options

      def initialize(object, inspector)
        super()
        @object = object
        @variables = object.instance_variables
        @inspector = inspector
        @options = inspector.options
      end

      def format
        vars = variables.map do |var|
          property = var.to_s[1..-1].to_sym # to_s because of some monkey patching done by Puppet.
          accessor = if object.respond_to?(:"#{property}=")
                       object.respond_to?(property) ? :accessor : :writer
                     else
                       object.respond_to?(property) ? :reader : nil
                     end
          if accessor
            ["attr_#{accessor} :#{property}", var]
          else
            [var.to_s, var]
          end
        end

        data = (options[:sort_vars] ? vars.sort : vars).map do |declaration, var|
          key = left_aligned do
            align(declaration, declaration.size)
          end

          unless options[:plain]
            key = if key =~ /(@\w+)/
                    key.sub(Regexp.last_match(1), colorize(Regexp.last_match(1), :variable))
                  else
                    key.sub(/(attr_\w+)\s(:\w+)/, "#{colorize('\\1', :keyword)} #{colorize('\\2', :method)}")
                  end
          end

          indented do
            key + colorize(' = ', :hash) + inspector.awesome(object.instance_variable_get(var))
          end
        end

        if options[:multiline]
          "#<#{awesome_instance}\n#{data.join(%(,\n))}\n#{outdent}>"
        else
          "#<#{awesome_instance} #{data.join(', ')}>"
        end
      end

      private

      def valid_instance_var?(variable_name)
        variable_name.to_s.start_with?('@')
      end

      def awesome_instance
        str = object.send(options[:class_name]).to_s
        return str unless options[:object_id]

        # We need to ensure that the original Kernel#format is used here instead of the one
        # defined above.
        # rubocop:disable Style/ColonMethodCall
        str + Kernel::format(':0x%08x', (object.__id__ * 2))
        # rubocop:enable Style/ColonMethodCall
      end

      def left_aligned
        current = options[:indent]
        options[:indent] = 0
        yield
      ensure
        options[:indent] = current
      end
    end
  end
end
