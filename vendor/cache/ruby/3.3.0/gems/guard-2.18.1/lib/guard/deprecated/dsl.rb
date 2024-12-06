require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

module Guard
  module Deprecated
    module Dsl
      def self.add_deprecated(dsl_klass)
        dsl_klass.send(:extend, ClassMethods)
      end

      MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-EOS.gsub(/^\s*/, "")
        For more information on how to upgrade for Guard 2.0, please head over
        to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
      EOS

      module ClassMethods
        # @deprecated Use
        # `Guard::Guardfile::Evaluator.new(options).evaluate_guardfile`
        # instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How
        # to upgrade for Guard 2.0
        #
        EVALUATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard::Dsl.evaluate_guardfile(options)' is
          deprecated.

          Please use
          'Guard::Guardfile::Evaluator.new(options).evaluate_guardfile'
          instead.

          #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-1'}
        EOS

        def evaluate_guardfile(options = {})
          require "guard/guardfile/evaluator"
          require "guard/ui"

          UI.deprecation(EVALUATE_GUARDFILE)
          ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
        end
      end
    end
  end
end
