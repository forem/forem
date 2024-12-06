# frozen_string_literal: true

module Anyway
  module Ext
    # Extend Object through refinements
    module DeepDup
      refine ::Hash do
        # Based on ActiveSupport http://api.rubyonrails.org/classes/Hash.html#method-i-deep_dup
        def deep_dup
          each_with_object(dup) do |(key, value), hash|
            hash[key] = if value.is_a?(::Hash) || value.is_a?(::Array)
              value.deep_dup
            else
              value
            end
          end
        end
      end

      refine ::Array do
        # From ActiveSupport http://api.rubyonrails.org/classes/Array.html#method-i-deep_dup
        def deep_dup
          map do |value|
            if value.is_a?(::Hash) || value.is_a?(::Array)
              value.deep_dup
            else
              value
            end
          end
        end
      end

      refine ::Object do
        def deep_dup
          dup
        end
      end

      refine ::Module do
        def deep_dup
          self
        end
      end

      using self
    end
  end
end
