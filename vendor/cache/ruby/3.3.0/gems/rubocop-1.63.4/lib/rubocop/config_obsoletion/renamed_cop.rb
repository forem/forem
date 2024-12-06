# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for renaming
    # a cop or moving it to a new department.
    # @api private
    class RenamedCop < CopRule
      attr_reader :new_name

      def initialize(config, old_name, new_name)
        super(config, old_name)
        @new_name = new_name
      end

      def rule_message
        "The `#{old_name}` cop has been #{verb} to `#{new_name}`."
      end

      private

      def moved?
        old_badge = Cop::Badge.parse(old_name)
        new_badge = Cop::Badge.parse(new_name)

        old_badge.department != new_badge.department && old_badge.cop_name == new_badge.cop_name
      end

      def verb
        moved? ? 'moved' : 'renamed'
      end
    end
  end
end
