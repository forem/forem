# frozen_string_literal: true

require 'capybara/selector/filters/base'

module Capybara
  class Selector
    module Filters
      class NodeFilter < Base
        def initialize(name, matcher, block, **options)
          super
          @block = if boolean?
            proc do |node, value|
              error_cnt = errors.size
              block.call(node, value).tap do |res|
                add_error("Expected #{name} #{value} but it wasn't") if !res && error_cnt == errors.size
              end
            end
          else
            block
          end
        end

        def matches?(node, name, value, context = nil)
          apply(node, name, value, true, context)
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end
end
