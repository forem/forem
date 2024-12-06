# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that accessor methods are named properly. Applies
      # to both instance and class methods.
      #
      # NOTE: Offenses are only registered for methods with the expected
      # arity. Getters (`get_attribute`) must have no arguments to be
      # registered, and setters (`set_attribute(value)`) must have exactly
      # one.
      #
      # @example
      #   # bad
      #   def set_attribute(value)
      #   end
      #
      #   # good
      #   def attribute=(value)
      #   end
      #
      #   # bad
      #   def get_attribute
      #   end
      #
      #   # good
      #   def attribute
      #   end
      #
      #   # accepted, incorrect arity for getter
      #   def get_value(attr)
      #   end
      #
      #   # accepted, incorrect arity for setter
      #   def set_value
      #   end
      class AccessorMethodName < Base
        MSG_READER = 'Do not prefix reader method names with `get_`.'
        MSG_WRITER = 'Do not prefix writer method names with `set_`.'

        def on_def(node)
          return unless bad_reader_name?(node) || bad_writer_name?(node)

          message = message(node)

          add_offense(node.loc.name, message: message)
        end
        alias on_defs on_def

        private

        def message(node)
          if bad_reader_name?(node)
            MSG_READER
          elsif bad_writer_name?(node)
            MSG_WRITER
          end
        end

        def bad_reader_name?(node)
          node.method_name.to_s.start_with?('get_') && !node.arguments?
        end

        def bad_writer_name?(node)
          node.method_name.to_s.start_with?('set_') &&
            node.arguments.one? &&
            node.first_argument.arg_type?
        end
      end
    end
  end
end
