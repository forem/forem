# frozen_string_literal: true

class Capybara::Selenium::Node
  #
  # @api private
  #
  class ModifierKeysStack
    def initialize
      @stack = []
    end

    def include?(key)
      @stack.flatten.include?(key)
    end

    def press(key)
      @stack.last.push(key)
    end

    def push
      @stack.push []
    end

    def pop
      @stack.pop
    end
  end
end
