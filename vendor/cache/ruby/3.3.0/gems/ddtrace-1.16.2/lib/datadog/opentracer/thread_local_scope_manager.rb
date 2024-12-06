require_relative '../core/utils/sequence'

module Datadog
  module OpenTracer
    # OpenTracing adapter for thread local scope management
    # @public_api
    class ThreadLocalScopeManager < ScopeManager
      def initialize(*args, &block)
        super(*args, &block)
        @thread_key = "dd_opentracer_context_#{ThreadLocalScopeManager.next_instance_id}".to_sym
      end

      ruby2_keywords :initialize if respond_to?(:ruby2_keywords, true)

      # Make a span instance active.
      #
      # @param span [Span] the Span that should become active
      # @param finish_on_close [Boolean] whether the Span should automatically be
      #   finished when Scope#close is called
      # @return [Scope] instance to control the end of the active period for the
      #  Span. It is a programming error to neglect to call Scope#close on the
      #  returned instance.
      def activate(span, finish_on_close: true)
        ThreadLocalScope.new(
          manager: self,
          span: span,
          finish_on_close: finish_on_close
        ).tap do |scope|
          set_scope(scope)
        end
      end

      # @return [Scope] the currently active Scope which can be used to access the
      # currently active Span.
      #
      # If there is a non-null Scope, its wrapped Span becomes an implicit parent
      # (as Reference#CHILD_OF) of any newly-created Span at Tracer#start_active_span
      # or Tracer#start_span time.
      def active
        Thread.current[@thread_key]
      end

      # Ensure two instances of {FiberLocalContext} do not conflict.
      # We previously used {FiberLocalContext#object_id} to ensure uniqueness
      # but the VM is allowed to reuse `object_id`, allow for the possibility that
      # a new FiberLocalContext would be able to read an old FiberLocalContext's
      # value.
      UNIQUE_INSTANCE_MUTEX = Mutex.new
      UNIQUE_INSTANCE_GENERATOR = Datadog::Core::Utils::Sequence.new

      private_constant :UNIQUE_INSTANCE_MUTEX, :UNIQUE_INSTANCE_GENERATOR

      def self.next_instance_id
        UNIQUE_INSTANCE_MUTEX.synchronize { UNIQUE_INSTANCE_GENERATOR.next }
      end

      private

      def set_scope(scope)
        Thread.current[@thread_key] = scope
      end
    end
  end
end
