# frozen_string_literal: true

require 'capybara/selector/filters/base'

module Capybara
  class Selector
    module Filters
      class ExpressionFilter < Base
        def apply_filter(expr, name, value, selector)
          apply(expr, name, value, expr, selector)
        end
      end

      class IdentityExpressionFilter < ExpressionFilter
        def initialize(name); super(name, nil, nil); end
        def default?; false; end
        def matcher?; false; end
        def apply_filter(expr, _name, _value, _ctx); expr; end
      end
    end
  end
end
