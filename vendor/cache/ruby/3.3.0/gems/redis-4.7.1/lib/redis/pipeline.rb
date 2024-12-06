# frozen_string_literal: true

require "delegate"

class Redis
  class PipelinedConnection
    def initialize(pipeline)
      @pipeline = pipeline
    end

    include Commands

    def db
      @pipeline.db
    end

    def db=(db)
      @pipeline.db = db
    end

    def pipelined
      yield self
    end

    def call_pipeline(pipeline)
      @pipeline.call_pipeline(pipeline)
      nil
    end

    private

    def synchronize
      yield self
    end

    def send_command(command, &block)
      @pipeline.call(command, &block)
    end

    def send_blocking_command(command, timeout, &block)
      @pipeline.call_with_timeout(command, timeout, &block)
    end
  end

  class Pipeline
    REDIS_INTERNAL_PATH = File.expand_path("..", __dir__).freeze
    # Redis use MonitorMixin#synchronize and this class use DelegateClass which we want to filter out.
    # Both are in the stdlib so we can simply filter the entire stdlib out.
    STDLIB_PATH = File.expand_path("..", MonitorMixin.instance_method(:synchronize).source_location.first).freeze

    class << self
      def deprecation_warning(method, caller_locations) # :nodoc:
        callsite = caller_locations.find { |l| !l.path.start_with?(REDIS_INTERNAL_PATH, STDLIB_PATH) }
        callsite ||= caller_locations.last # The caller_locations should be large enough, but just in case.
        ::Redis.deprecate! <<~MESSAGE
          Pipelining commands on a Redis instance is deprecated and will be removed in Redis 5.0.0.

          redis.#{method} do
            redis.get("key")
          end

          should be replaced by

          redis.#{method} do |pipeline|
            pipeline.get("key")
          end

          (called from #{callsite}}
        MESSAGE
      end
    end

    attr_accessor :db
    attr_reader :client

    attr :futures
    alias materialized_futures futures

    def initialize(client)
      @client = client.is_a?(Pipeline) ? client.client : client
      @with_reconnect = true
      @shutdown = false
      @futures = []
    end

    def timeout
      client.timeout
    end

    def with_reconnect?
      @with_reconnect
    end

    def without_reconnect?
      !@with_reconnect
    end

    def shutdown?
      @shutdown
    end

    def empty?
      @futures.empty?
    end

    def call(command, timeout: nil, &block)
      # A pipeline that contains a shutdown should not raise ECONNRESET when
      # the connection is gone.
      @shutdown = true if command.first == :shutdown
      future = Future.new(command, block, timeout)
      @futures << future
      future
    end

    def call_with_timeout(command, timeout, &block)
      call(command, timeout: timeout, &block)
    end

    def call_pipeline(pipeline)
      @shutdown = true if pipeline.shutdown?
      @futures.concat(pipeline.materialized_futures)
      @db = pipeline.db
      nil
    end

    def commands
      @futures.map(&:_command)
    end

    def timeouts
      @futures.map(&:timeout)
    end

    def with_reconnect(val = true)
      @with_reconnect = false unless val
      yield
    end

    def without_reconnect(&blk)
      with_reconnect(false, &blk)
    end

    def finish(replies, &blk)
      if blk
        futures.each_with_index.map do |future, i|
          future._set(blk.call(replies[i]))
        end
      else
        futures.each_with_index.map do |future, i|
          future._set(replies[i])
        end
      end
    end

    class Multi < self
      def finish(replies)
        exec = replies.last

        return if exec.nil? # The transaction failed because of WATCH.

        # EXEC command failed.
        raise exec if exec.is_a?(CommandError)

        if exec.size < futures.size
          # Some command wasn't recognized by Redis.
          command_error = replies.detect { |r| r.is_a?(CommandError) }
          raise command_error
        end

        super(exec) do |reply|
          # Because an EXEC returns nested replies, hiredis won't be able to
          # convert an error reply to a CommandError instance itself. This is
          # specific to MULTI/EXEC, so we solve this here.
          reply.is_a?(::RuntimeError) ? CommandError.new(reply.message) : reply
        end
      end

      def materialized_futures
        if empty?
          []
        else
          [
            Future.new([:multi], nil, 0),
            *futures,
            MultiFuture.new(futures)
          ]
        end
      end

      def timeouts
        if empty?
          []
        else
          [nil, *super, nil]
        end
      end

      def commands
        if empty?
          []
        else
          [[:multi]] + super + [[:exec]]
        end
      end
    end
  end

  class DeprecatedPipeline < DelegateClass(Pipeline)
    def initialize(pipeline)
      super(pipeline)
      @deprecation_displayed = false
    end

    def __getobj__
      unless @deprecation_displayed
        Pipeline.deprecation_warning("pipelined", Kernel.caller_locations(1, 10))
        @deprecation_displayed = true
      end
      @delegate_dc_obj
    end
  end

  class DeprecatedMulti < DelegateClass(Pipeline::Multi)
    def initialize(pipeline)
      super(pipeline)
      @deprecation_displayed = false
    end

    def __getobj__
      unless @deprecation_displayed
        Pipeline.deprecation_warning("multi", Kernel.caller_locations(1, 10))
        @deprecation_displayed = true
      end
      @delegate_dc_obj
    end
  end

  class FutureNotReady < RuntimeError
    def initialize
      super("Value will be available once the pipeline executes.")
    end
  end

  class Future < BasicObject
    FutureNotReady = ::Redis::FutureNotReady.new

    attr_reader :timeout

    def initialize(command, transformation, timeout)
      @command = command
      @transformation = transformation
      @timeout = timeout
      @object = FutureNotReady
    end

    def ==(_other)
      message = +"The methods == and != are deprecated for Redis::Future and will be removed in 5.0.0"
      message << " - You probably meant to call .value == or .value !="
      message << " (#{::Kernel.caller(1, 1).first})\n"

      ::Redis.deprecate!(message)

      super
    end

    def inspect
      "<Redis::Future #{@command.inspect}>"
    end

    def _set(object)
      @object = @transformation ? @transformation.call(object) : object
      value
    end

    def _command
      @command
    end

    def value
      ::Kernel.raise(@object) if @object.is_a?(::RuntimeError)
      @object
    end

    def is_a?(other)
      self.class.ancestors.include?(other)
    end

    def class
      Future
    end
  end

  class MultiFuture < Future
    def initialize(futures)
      @futures = futures
      @command = [:exec]
    end

    def _set(replies)
      @futures.each_with_index do |future, index|
        future._set(replies[index])
      end
      replies
    end
  end
end
