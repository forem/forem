module Regexp::Expression
  module Keep
    # TOOD: in regexp_parser v3.0.0 this should possibly be a Subexpression
    #       that contains all expressions to its left.
    class Mark < Regexp::Expression::Base; end
  end
end
