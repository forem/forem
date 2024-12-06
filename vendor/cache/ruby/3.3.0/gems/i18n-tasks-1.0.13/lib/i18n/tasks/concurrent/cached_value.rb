# frozen_string_literal: true

module I18n::Tasks::Concurrent
  # A thread-safe memoized value.
  # The given computation is guaranteed to be invoked at most once.
  # @since 0.9.25
  class CachedValue
    NULL = Object.new

    # @param [Proc] computation The computation that returns the value to cache.
    def initialize(&computation)
      @computation = computation
      @mutex = Mutex.new
      @result = NULL
    end

    # @return [Object] Result of the computation.
    def get
      return get_result_volatile unless get_result_volatile == NULL

      @mutex.synchronize do
        next unless get_result_volatile == NULL

        set_result_volatile @computation.call
        @computation = nil
      end
      get_result_volatile
    end

    private

    # Ruby instance variable volatility is currently unspecified:
    # https://bugs.ruby-lang.org/issues/11539
    #
    # Below are the implementations for major ruby engines, based on concurrent-ruby.
    # rubocop:disable Lint/DuplicateMethods,Naming/AccessorMethodName
    case RUBY_ENGINE
    when 'rbx'
      def get_result_volatile
        Rubinius.memory_barrier
        @result
      end

      def set_result_volatile(value)
        @result = value
        Rubinius.memory_barrier
      end
    else
      def get_result_volatile
        @result
      end

      def set_result_volatile(value)
        @result = value
      end
    end
    # rubocop:enable Lint/DuplicateMethods,Naming/AccessorMethodName
  end
end
