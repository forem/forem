# frozen_string_literal: true

require 'capybara/selector/filters/base'

module Capybara
  class Selector
    module Filters
      class LocatorFilter < NodeFilter
        def initialize(block, **options)
          super(nil, nil, block, **options)
        end

        def matches?(node, value, context = nil, exact:)
          apply(node, value, true, context, exact: exact, format: context&.default_format)
        rescue Capybara::ElementNotFound
          false
        end

      private

        def apply(subject, value, skip_value, ctx, **options)
          return skip_value if skip?(value)

          filter_context(ctx).instance_exec(subject, value, **options, &@block)
        end
      end
    end
  end
end
