require 'honeybadger/plugin'
require 'honeybadger/backtrace'

module Honeybadger
  module Plugins
    module LocalVariables
      module ExceptionExtension
        def self.included(base)
          base.send(:alias_method, :set_backtrace_without_honeybadger, :set_backtrace)
          base.send(:alias_method, :set_backtrace, :set_backtrace_with_honeybadger)
        end

        def set_backtrace_with_honeybadger(*args, &block)
          if caller.none? { |loc| loc.match(::Honeybadger::Backtrace::Line::INPUT_FORMAT) && Regexp.last_match(1) == __FILE__ }
            @__honeybadger_bindings_stack = binding.callers.drop(1)
          end

          set_backtrace_without_honeybadger(*args, &block)
        end

        def __honeybadger_bindings_stack
          @__honeybadger_bindings_stack || []
        end
      end

      Plugin.register do
        requirement { config[:'exceptions.local_variables'] }
        requirement { defined?(::BindingOfCaller) }
        requirement do
          if res = defined?(::BetterErrors)
            logger.warn("The local variables feature is incompatible with the " \
                        "better_errors gem; to remove this warning, set " \
                        "exceptions.local_variables to false for environments " \
                        "which load better_errors.")
          end
          !res
        end
        requirement { !::Exception.included_modules.include?(ExceptionExtension) }

        execution { ::Exception.send(:include, ExceptionExtension) }
      end
    end
  end
end
