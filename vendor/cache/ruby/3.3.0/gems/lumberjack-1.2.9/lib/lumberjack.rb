# frozen_string_literals: true

require "rbconfig"
require "time"
require "securerandom"
require "logger"

module Lumberjack
  LINE_SEPARATOR = ((RbConfig::CONFIG["host_os"] =~ /mswin/i) ? "\r\n" : "\n")

  require_relative "lumberjack/severity"
  require_relative "lumberjack/formatter"

  require_relative "lumberjack/context"
  require_relative "lumberjack/log_entry"
  require_relative "lumberjack/device"
  require_relative "lumberjack/logger"
  require_relative "lumberjack/tags"
  require_relative "lumberjack/tag_formatter"
  require_relative "lumberjack/tagged_logger_support"
  require_relative "lumberjack/tagged_logging"
  require_relative "lumberjack/template"
  require_relative "lumberjack/rack"

  class << self
    # Define a unit of work within a block. Within the block supplied to this
    # method, calling +unit_of_work_id+ will return the same value that can
    # This can then be used for tying together log entries.
    #
    # You can specify the id for the unit of work if desired. If you don't supply
    # it, a 12 digit hexidecimal number will be automatically generated for you.
    #
    # For the common use case of treating a single web request as a unit of work, see the
    # Lumberjack::Rack::UnitOfWork class.
    #
    # @param [String] id The id for the unit of work.
    # @return [void]
    def unit_of_work(id = nil)
      id ||= SecureRandom.hex(6)
      context do
        context[:unit_of_work_id] = id
        yield
      end
    end

    # Get the UniqueIdentifier for the current unit of work.
    #
    # @return [String, nil] The id for the current unit of work.
    def unit_of_work_id
      context[:unit_of_work_id]
    end

    # Contexts can be used to store tags that will be attached to all log entries in the block.
    #
    # If this method is called with a block, it will set a logging context for the scope of a block.
    # If there is already a context in scope, a new one will be created that inherits
    # all the tags of the parent context.
    #
    # Otherwise, it will return the current context. If one doesn't exist, it will return a new one
    # but that context will not be in any scope.
    #
    # @return [Lumberjack::Context] The current context if called without a block.
    def context(&block)
      current_context = Thread.current[:lumberjack_context]
      if block
        use_context(Context.new(current_context), &block)
      else
        current_context || Context.new
      end
    end

    # Set the context to use within a block.
    #
    # @param [Lumberjack::Context] context The context to use within the block.
    # @return [Object] The result of the block.
    def use_context(context, &block)
      current_context = Thread.current[:lumberjack_context]
      begin
        Thread.current[:lumberjack_context] = (context || Context.new)
        yield
      ensure
        Thread.current[:lumberjack_context] = current_context
      end
    end

    # Return true if inside a context block.
    #
    # @return [Boolean]
    def context?
      !!Thread.current[:lumberjack_context]
    end

    # Return the tags from the current context or nil if there are no tags.
    #
    # @return [Hash, nil]
    def context_tags
      context = Thread.current[:lumberjack_context]
      context&.tags
    end

    # Set tags on the current context
    #
    # @param [Hash] tags The tags to set.
    # @return [void]
    def tag(tags)
      context = Thread.current[:lumberjack_context]
      context&.tag(tags)
    end
  end
end
