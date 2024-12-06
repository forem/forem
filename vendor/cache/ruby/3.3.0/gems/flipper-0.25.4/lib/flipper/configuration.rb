module Flipper
  class Configuration
    def initialize(options = {})
      @default = -> { Flipper.new(adapter) }
      @adapter = -> { Flipper::Adapters::Memory.new }
    end

    # The default adapter to use.
    #
    # Pass a block to assign the adapter, and invoke without a block to
    # return the configured adapter instance.
    #
    #   Flipper.configure do |config|
    #     config.adapter # => instance of default Memory adapter
    #
    #     # Configure it to use the ActiveRecord adapter
    #     config.adapter do
    #       require "flipper/adapters/active_record"
    #       Flipper::Adapters::ActiveRecord.new
    #     end
    #
    #     config.adapter # => instance of ActiveRecord adapter
    #  end
    #
    def adapter(&block)
      if block_given?
        @adapter = block
      else
        @adapter.call
      end
    end

    # Controls the default instance for flipper. When used with a block it
    # assigns a new default block to use to generate an instance. When used
    # without a block, it performs a block invocation and returns the result.
    #
    #   configuration = Flipper::Configuration.new
    #   configuration.default # => Flipper::DSL instance using Memory adapter
    #
    #   # sets the default block to generate a new instance using ActiveRecord adapter
    #   configuration.default do
    #     require "flipper/adapters/active_record"
    #     Flipper.new(Flipper::Adapters::ActiveRecord.new)
    #   end
    #
    #   configuration.default # => Flipper::DSL instance using ActiveRecord adapter
    #
    # Returns result of default block invocation if called without block. If
    # called with block, assigns the default block.
    def default(&block)
      if block_given?
        @default = block
      else
        @default.call
      end
    end
  end
end
