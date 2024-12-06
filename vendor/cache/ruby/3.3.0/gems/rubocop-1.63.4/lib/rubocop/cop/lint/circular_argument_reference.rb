# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for circular argument references in optional keyword
      # arguments and optional ordinal arguments.
      #
      # This cop mirrors a warning produced by MRI since 2.2.
      #
      # @example
      #
      #   # bad
      #
      #   def bake(pie: pie)
      #     pie.heat_up
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def bake(pie:)
      #     pie.refrigerate
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def bake(pie: self.pie)
      #     pie.feed_to(user)
      #   end
      #
      # @example
      #
      #   # bad
      #
      #   def cook(dry_ingredients = dry_ingredients)
      #     dry_ingredients.reduce(&:+)
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def cook(dry_ingredients = self.dry_ingredients)
      #     dry_ingredients.combine
      #   end
      class CircularArgumentReference < Base
        MSG = 'Circular argument reference - `%<arg_name>s`.'

        def on_kwoptarg(node)
          check_for_circular_argument_references(*node)
        end

        def on_optarg(node)
          check_for_circular_argument_references(*node)
        end

        private

        def check_for_circular_argument_references(arg_name, arg_value)
          return unless arg_value.lvar_type?
          return unless arg_value.to_a == [arg_name]

          add_offense(arg_value, message: format(MSG, arg_name: arg_name))
        end
      end
    end
  end
end
