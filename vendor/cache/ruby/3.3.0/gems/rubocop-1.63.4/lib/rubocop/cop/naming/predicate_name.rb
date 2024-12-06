# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks that predicate methods names end with a question mark and
      # do not start with a forbidden prefix.
      #
      # A method is determined to be a predicate method if its name starts
      # with one of the prefixes defined in the `NamePrefix` configuration.
      # You can change what prefixes are considered by changing this option.
      # Any method name that starts with one of these prefixes is required by
      # the cop to end with a `?`. Other methods can be allowed by adding to
      # the `AllowedMethods` configuration.
      #
      # NOTE: The `is_a?` method is allowed by default.
      #
      # If `ForbiddenPrefixes` is set, methods that start with the configured
      # prefixes will not be allowed and will be removed by autocorrection.
      #
      # In other words, if `ForbiddenPrefixes` is empty, a method named `is_foo`
      # will register an offense only due to the lack of question mark (and will be
      # autocorrected to `is_foo?`). If `ForbiddenPrefixes` contains `is_`,
      # `is_foo` will register an offense both because the ? is missing and because of
      # the `is_` prefix, and will be corrected to `foo?`.
      #
      # NOTE: `ForbiddenPrefixes` is only applied to prefixes in `NamePrefix`;
      # a prefix in the former but not the latter will not be considered by
      # this cop.
      #
      # @example
      #   # bad
      #   def is_even(value)
      #   end
      #
      #   def is_even?(value)
      #   end
      #
      #   # good
      #   def even?(value)
      #   end
      #
      #   # bad
      #   def has_value
      #   end
      #
      #   def has_value?
      #   end
      #
      #   # good
      #   def value?
      #   end
      #
      # @example AllowedMethods: ['is_a?'] (default)
      #   # good
      #   def is_a?(value)
      #   end
      #
      class PredicateName < Base
        include AllowedMethods

        # @!method dynamic_method_define(node)
        def_node_matcher :dynamic_method_define, <<~PATTERN
          (send nil? #method_definition_macros
            (sym $_)
            ...)
        PATTERN

        def on_send(node)
          dynamic_method_define(node) do |method_name|
            predicate_prefixes.each do |prefix|
              next if allowed_method_name?(method_name.to_s, prefix)

              add_offense(
                node.first_argument.source_range,
                message: message(method_name, expected_name(method_name.to_s, prefix))
              )
            end
          end
        end

        def on_def(node)
          predicate_prefixes.each do |prefix|
            method_name = node.method_name.to_s

            next if allowed_method_name?(method_name, prefix)

            add_offense(
              node.loc.name,
              message: message(method_name, expected_name(method_name, prefix))
            )
          end
        end
        alias on_defs on_def

        private

        def allowed_method_name?(method_name, prefix)
          !(method_name.start_with?(prefix) && # cheap check to avoid allocating Regexp
              method_name.match?(/^#{prefix}[^0-9]/)) ||
            method_name == expected_name(method_name, prefix) ||
            method_name.end_with?('=') ||
            allowed_method?(method_name)
        end

        def expected_name(method_name, prefix)
          new_name = if forbidden_prefixes.include?(prefix)
                       method_name.sub(prefix, '')
                     else
                       method_name.dup
                     end
          new_name << '?' unless method_name.end_with?('?')
          new_name
        end

        def message(method_name, new_name)
          "Rename `#{method_name}` to `#{new_name}`."
        end

        def forbidden_prefixes
          cop_config['ForbiddenPrefixes']
        end

        def predicate_prefixes
          cop_config['NamePrefix']
        end

        def method_definition_macros(macro_name)
          cop_config['MethodDefinitionMacros'].include?(macro_name.to_s)
        end
      end
    end
  end
end
