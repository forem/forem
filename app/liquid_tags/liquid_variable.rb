module Liquid
  class Variable
    def initialize(markup, _parse_context)
      @markup = markup
    end

    def render(_context)
      "{{#{@markup}}}"
    end
  end
end
