module Regexp::Expression
  module Backreference
    class Base < Regexp::Expression::Base
      attr_accessor :referenced_expression

      def initialize_copy(orig)
        exp_id = [self.class, self.starts_at]

        # prevent infinite recursion for recursive subexp calls
        copied = @@copied ||= {}
        self.referenced_expression =
          if copied[exp_id]
            orig.referenced_expression
          else
            copied[exp_id] = true
            orig.referenced_expression.dup
          end
        copied.clear

        super
      end
    end

    class Number < Backreference::Base
      attr_reader :number
      alias reference number

      def initialize(token, options = {})
        @number = token.text[/-?\d+/].to_i
        super
      end
    end

    class Name < Backreference::Base
      attr_reader :name
      alias reference name

      def initialize(token, options = {})
        @name = token.text[3..-2]
        super
      end
    end

    class NumberRelative     < Backreference::Number
      attr_accessor :effective_number
      alias reference effective_number
    end

    class NumberCall         < Backreference::Number; end
    class NameCall           < Backreference::Name; end
    class NumberCallRelative < Backreference::NumberRelative; end

    class NumberRecursionLevel < Backreference::NumberRelative
      attr_reader :recursion_level

      def initialize(token, options = {})
        super
        @number, @recursion_level = token.text[3..-2].split(/(?=[+-])/).map(&:to_i)
      end
    end

    class NameRecursionLevel < Backreference::Name
      attr_reader :recursion_level

      def initialize(token, options = {})
        super
        @name, recursion_level = token.text[3..-2].split(/(?=[+-])/)
        @recursion_level = recursion_level.to_i
      end
    end
  end

  # alias for symmetry between token symbol and Expression class name
  Backref = Backreference
end
