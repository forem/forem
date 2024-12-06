# frozen_string_literal: true

module XPath
  class Renderer
    def join(*expressions)
      expressions.join('/')
    end
  end
end

module XPath
  module DSL
    def join(*expressions)
      XPath::Expression.new(:join, *[self, expressions].flatten)
    end
  end
end
