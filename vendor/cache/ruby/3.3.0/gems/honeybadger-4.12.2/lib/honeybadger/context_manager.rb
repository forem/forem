require 'honeybadger/conversions'

module Honeybadger
  # @api private
  class ContextManager
    include Conversions

    def self.current
      Thread.current[:__hb_context_manager] ||= new
    end

    def initialize
      @mutex = Mutex.new
      _initialize
    end

    def clear!
      _initialize
    end

    # Internal helpers


    def set_context(hash)
      @mutex.synchronize do
        @context ||= {}
        @context.update(Context(hash))
      end
    end

    def get_context
      @mutex.synchronize { @context }
    end

    def set_rack_env(env)
      @mutex.synchronize { @rack_env = env }
    end

    def get_rack_env
      @mutex.synchronize { @rack_env }
    end

    private

    attr_accessor :custom, :rack_env

    def _initialize
      @mutex.synchronize do
        @context = nil
        @rack_env = nil
      end
    end

  end
end
