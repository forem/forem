# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class NumericLiterals < Base
        using RubyNext

        NAME = "numeric-literals"
        SYNTAX_PROBE = "2i + 1/2r"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.1.0")

        def on_rational(node)
          context.track! self

          val = node.children.first

          parts = [s(:int, val.numerator)]

          parts << s(:int, val.denominator) unless val.denominator == 1

          s(:send, nil, :Rational, *parts).tap do |new_node|
            replace(node.loc.expression, new_node)
          end
        end

        def on_complex(node)
          context.track! self

          val = node.children.first

          s(:send, nil, :Complex,
            s(:int, val.real),
            s(:int, val.imaginary)).tap do |new_node|
            replace(node.loc.expression, new_node)
          end
        end
      end
    end
  end
end
