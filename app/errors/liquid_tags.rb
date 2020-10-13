module LiquidTags
  module Errors
    class Error
    end

    # ParseContexts are options passed to initialize on a LiquidTag.
    # An error is raised if any of those options are invalid.
    class InvalidParseContext < Error
    end
  end
end
