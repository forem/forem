module Liquid
  class Variable
    def initialize(_markup, _parse_context)
      raise StandardError, "Liquid variables are disabled"
    end
  end
end
