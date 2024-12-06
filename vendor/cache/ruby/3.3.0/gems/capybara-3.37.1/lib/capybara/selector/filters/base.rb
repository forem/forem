# frozen_string_literal: true

module Capybara
  class Selector
    module Filters
      class Base
        def initialize(name, matcher, block, **options)
          @name = name
          @matcher = matcher
          @block = block
          @options = options
          @options[:valid_values] = [true, false] if options[:boolean]
        end

        def default?
          @options.key?(:default)
        end

        def default
          @options[:default]
        end

        def skip?(value)
          @options.key?(:skip_if) && value == @options[:skip_if]
        end

        def format
          @options[:format]
        end

        def matcher?
          !@matcher.nil?
        end

        def boolean?
          !!@options[:boolean]
        end

        def handles_option?(option_name)
          if matcher?
            @matcher.match? option_name
          else
            @name == option_name
          end
        end

      private

        def apply(subject, name, value, skip_value, ctx)
          return skip_value if skip?(value)

          unless valid_value?(value)
            raise ArgumentError,
                  "Invalid value #{value.inspect} passed to #{self.class.name.split('::').last} #{name}" \
                  "#{" : #{name}" if @name.is_a?(Regexp)}"
          end

          if @block.arity == 2
            filter_context(ctx).instance_exec(subject, value, &@block)
          else
            filter_context(ctx).instance_exec(subject, name, value, &@block)
          end
        end

        def filter_context(context)
          context || @block.binding.receiver
        end

        def valid_value?(value)
          return true unless @options.key?(:valid_values)

          Array(@options[:valid_values]).any? { |valid| valid === value } # rubocop:disable Style/CaseEquality
        end
      end
    end
  end
end
