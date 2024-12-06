# frozen_string_literal: true

module XPath
  class Expression
    attr_accessor :expression, :arguments
    include XPath::DSL

    def initialize(expression, *arguments)
      @expression = expression
      @arguments = arguments
    end

    def current
      self
    end

    def to_xpath(type = nil)
      Renderer.render(self, type)
    end
    alias_method :to_s, :to_xpath
  end
end
