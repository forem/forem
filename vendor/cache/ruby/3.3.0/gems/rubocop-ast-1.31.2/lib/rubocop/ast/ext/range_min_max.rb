# frozen_string_literal: true

module RuboCop
  module AST
    module Ext
      # Refinement to circumvent broken `Range#minmax` for infinity ranges in 2.6-
      module RangeMinMax
        if ::Range.instance_method(:minmax).owner != ::Range
          refine ::Range do
            def minmax
              [min, max]
            end
          end
        end
      end
    end
  end
end
