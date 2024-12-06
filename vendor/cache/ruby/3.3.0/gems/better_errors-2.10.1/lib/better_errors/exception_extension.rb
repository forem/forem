module BetterErrors
  module ExceptionExtension
    prepend_features Exception

    def set_backtrace(*)
      if caller_locations.none? { |loc| loc.path == __FILE__ }
        @__better_errors_bindings_stack = ::Kernel.binding.callers.drop(1)
      end

      super
    end

    def __better_errors_bindings_stack
      @__better_errors_bindings_stack || []
    end
  end
end
