require 'time'

require_relative '../core/environment/identity'
require_relative '../core/utils'
require_relative '../core/utils/time'
require_relative '../core/utils/safe_dup'

require_relative 'event'
require_relative 'metadata'
require_relative 'metadata/ext'
require_relative 'span'
require_relative 'utils'

module Datadog
  module Tracing
    # Represents the act of taking a span measurement.
    # It gives a Span a context which can be used to
    # build a Span. When completed, it yields the Span.
    #
    # @public_api
    class SpanOperation
      include Metadata

      # Span attributes
      # NOTE: In the future, we should drop the me
      attr_reader \
        :end_time,
        :id,
        :name,
        :parent_id,
        :resource,
        :service,
        :start_time,
        :trace_id,
        :type

      attr_accessor \
        :status

      def initialize(
        name,
        child_of: nil,
        events: nil,
        on_error: nil,
        parent_id: 0,
        resource: name,
        service: nil,
        start_time: nil,
        tags: nil,
        trace_id: nil,
        type: nil
      )
        # Ensure dynamically created strings are UTF-8 encoded.
        #
        # All strings created in Ruby land are UTF-8. The only sources of non-UTF-8 string are:
        # * Strings explicitly encoded as non-UTF-8.
        # * Some natively created string, although most natively created strings are UTF-8.
        self.name = name
        self.service = service
        self.type = type
        self.resource = resource

        @id = Tracing::Utils.next_id
        @parent_id = parent_id || 0
        @trace_id = trace_id || Tracing::Utils::TraceId.next_id

        @status = 0

        # start_time and end_time track wall clock. In Ruby, wall clock
        # has less accuracy than monotonic clock, so if possible we look to only use wall clock
        # to measure duration when a time is supplied by the user, or if monotonic clock
        # is unsupported.
        @start_time = nil
        @end_time = nil

        # duration_start and duration_end track monotonic clock, and may remain nil in cases where it
        # is known that we have to use wall clock to measure duration.
        @duration_start = nil
        @duration_end = nil

        # Set tags if provided.
        set_tags(tags) if tags

        # Only set parent if explicitly provided.
        # We don't want it to override context-derived
        # IDs if it's a distributed trace w/o a parent span.
        parent = child_of
        self.parent = parent if parent

        # Some other SpanOperation-specific behavior
        @events = events || Events.new
        @span = nil

        # Subscribe :on_error event
        @events.on_error.wrap_default(&on_error) if on_error.is_a?(Proc)

        # Start the span with start time, if given.
        start(start_time) if start_time
      end

      # Operation name.
      # @!attribute [rw] name
      # @return [String]
      def name=(name)
        raise ArgumentError, "SpanOperation name can't be nil" unless name

        @name = Core::Utils.utf8_encode(name)
      end

      # Span type.
      # @!attribute [rw] type
      # @return [String
      def type=(type)
        @type = type.nil? ? nil : Core::Utils.utf8_encode(type) # Allow this to be explicitly set to nil
      end

      # Service name.
      # @!attribute [rw] service
      # @return [String
      def service=(service)
        @service = service.nil? ? nil : Core::Utils.utf8_encode(service) # Allow this to be explicitly set to nil
      end

      # Span resource.
      # @!attribute [rw] resource
      # @return [String
      def resource=(resource)
        @resource = resource.nil? ? nil : Core::Utils.utf8_encode(resource) # Allow this to be explicitly set to nil
      end

      def measure
        raise ArgumentError, 'Must provide block to measure!' unless block_given?
        # TODO: Should we just invoke the block and skip tracing instead?
        raise AlreadyStartedError if started?

        return_value = nil

        begin
          # If span fails to start, don't prevent the operation from
          # running, to minimize impact on normal application function.
          begin
            start
          rescue StandardError => e
            Datadog.logger.debug { "Failed to start span: #{e}" }
          ensure
            # We should yield to the provided block when possible, as this
            # block is application code that we don't want to hinder.
            # * We don't yield during a fatal error, as the application is likely trying to
            #   end its execution (either due to a system error or graceful shutdown).
            return_value = yield(self) unless e && !e.is_a?(StandardError)
          end
        # rubocop:disable Lint/RescueException
        # Here we really want to catch *any* exception, not only StandardError,
        # as we really have no clue of what is in the block,
        # and it is user code which should be executed no matter what.
        # It's not a problem since we re-raise it afterwards so for example a
        # SignalException::Interrupt would still bubble up.
        rescue Exception => e
          # Stop the span first, so timing is a more accurate.
          # If the span failed to start, timing may be inaccurate,
          # but this is not really a serious concern.
          stop

          # Trigger the on_error event
          events.on_error.publish(self, e)

          # We must finish the span to trigger callbacks,
          # and build the final span.
          finish

          raise e
        # Use an ensure block here to make sure the span closes.
        # NOTE: It's not sufficient to use "else": when a function
        #       uses "return", it will skip "else".
        ensure
          # Finish the span
          # NOTE: If an error was raised, this "finish" might be redundant.
          finish unless finished?
        end
        # rubocop:enable Lint/RescueException

        return_value
      end

      def start(start_time = nil)
        # Span can only be started once
        return self if started?

        # Trigger before_start event
        events.before_start.publish(self)

        # Start the span
        @start_time = start_time || Core::Utils::Time.now.utc
        @duration_start = start_time.nil? ? duration_marker : nil

        self
      end

      # Mark the span stopped at the current time
      def stop(stop_time = nil)
        # A span should not be stopped twice. Note that this is not thread-safe,
        # stop is called from multiple threads, a given span might be stopped
        # several times. Again, one should not do this, so this test is more a
        # fallback to avoid very bad things and protect you in most common cases.
        return if stopped?

        now = Core::Utils::Time.now.utc

        # Provide a default start_time if unset.
        # Using `now` here causes duration to be 0; this is expected
        # behavior when start_time is unknown.
        start(stop_time || now) unless started?

        @end_time = stop_time || now
        @duration_end = stop_time.nil? ? duration_marker : nil

        # Trigger after_stop event
        events.after_stop.publish(self)

        self
      end

      # Return whether the duration is started or not
      def started?
        !@start_time.nil?
      end

      # Return whether the duration is stopped or not.
      def stopped?
        !@end_time.nil?
      end

      # for backwards compatibility
      def start_time=(time)
        time.tap { start(time) }
      end

      # for backwards compatibility
      def end_time=(time)
        time.tap { stop(time) }
      end

      def finish(end_time = nil)
        # Returned memoized span if already finished
        return span if finished?

        # Stop timing
        stop(end_time)

        # Build span
        # Memoize for performance reasons
        @span = build_span

        # Trigger after_finish event
        events.after_finish.publish(span, self)

        span
      end

      def finished?
        !span.nil?
      end

      def duration
        return @duration_end - @duration_start if @duration_start && @duration_end
        return @end_time - @start_time if @start_time && @end_time
      end

      def set_error(e)
        @status = Metadata::Ext::Errors::STATUS
        super
      end

      # Return a string representation of the span.
      def to_s
        "SpanOperation(name:#{@name},sid:#{@id},tid:#{@trace_id},pid:#{@parent_id})"
      end

      # Return the hash representation of the current span.
      def to_hash
        h = {
          error: @status,
          id: @id,
          meta: meta,
          metrics: metrics,
          name: @name,
          parent_id: @parent_id,
          resource: @resource,
          service: @service,
          trace_id: @trace_id,
          type: @type
        }

        if stopped?
          h[:start] = start_time_nano
          h[:duration] = duration_nano
        end

        h
      end

      # Return a human readable version of the span
      def pretty_print(q)
        start_time = (self.start_time.to_f * 1e9).to_i
        end_time = (self.end_time.to_f * 1e9).to_i
        q.group 0 do
          q.breakable
          q.text "Name: #{@name}\n"
          q.text "Span ID: #{@id}\n"
          q.text "Parent ID: #{@parent_id}\n"
          q.text "Trace ID: #{@trace_id}\n"
          q.text "Type: #{@type}\n"
          q.text "Service: #{@service}\n"
          q.text "Resource: #{@resource}\n"
          q.text "Error: #{@status}\n"
          q.text "Start: #{start_time}\n"
          q.text "End: #{end_time}\n"
          q.text "Duration: #{duration.to_f if stopped?}\n"
          q.group(2, 'Tags: [', "]\n") do
            q.breakable
            q.seplist meta.each do |key, value|
              q.text "#{key} => #{value}"
            end
          end
          q.group(2, 'Metrics: [', ']') do
            q.breakable
            q.seplist metrics.each do |key, value|
              q.text "#{key} => #{value}"
            end
          end
        end
      end

      # Callback behavior
      class Events
        include Tracing::Events

        DEFAULT_ON_ERROR = proc { |span_op, error| span_op.set_error(error) unless span_op.nil? }

        attr_reader \
          :after_finish,
          :after_stop,
          :before_start

        def initialize(on_error: nil)
          @after_finish = AfterFinish.new
          @after_stop = AfterStop.new
          @before_start = BeforeStart.new
        end

        # This event is lazily initialized as error paths
        # are normally less common that non-error paths.
        def on_error
          @on_error ||= OnError.new(DEFAULT_ON_ERROR)
        end

        # Triggered when the span is finished, regardless of error.
        class AfterFinish < Tracing::Event
          def initialize
            super(:after_finish)
          end
        end

        # Triggered when the span is stopped, regardless of error.
        class AfterStop < Tracing::Event
          def initialize
            super(:after_stop)
          end
        end

        # Triggered just before the span is started.
        class BeforeStart < Tracing::Event
          def initialize
            super(:before_start)
          end
        end

        # Triggered when the span raises an error during measurement.
        class OnError
          def initialize(default)
            @handler = default
          end

          # Call custom error handler but fallback to default behavior on failure.

          # DEV: Revisit this before full 1.0 release.
          # It seems like OnError wants to behave like a middleware stack,
          # where each "subscriber"'s executed is chained to the previous one.
          # This is different from how {Tracing::Event} works, and might be incompatible.
          def wrap_default
            original = @handler

            @handler = proc do |op, error|
              begin
                yield(op, error)
              rescue StandardError => e
                Datadog.logger.debug do
                  "Custom on_error handler #{@handler} failed, using fallback behavior. \
                  Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
                end

                original.call(op, error) if original
              end
            end
          end

          def publish(*args)
            begin
              @handler.call(*args)
            rescue StandardError => e
              Datadog.logger.debug do
                "Error in on_error handler '#{@default}': #{e.class.name} #{e.message} at #{Array(e.backtrace).first}"
              end
            end

            true
          end
        end
      end

      # Error when the span attempts to start again after being started
      class AlreadyStartedError < StandardError
        def message
          'Cannot measure an already started span!'.freeze
        end
      end

      private

      # Keep span reference private: we don't want users
      # modifying the finalized span from the operation after
      # it has been finished.
      attr_reader \
        :events,
        :parent,
        :span

      # Create a Span from the operation which represents
      # the finalized measurement. We #dup here to prevent
      # mutation by reference; when this span is returned,
      # we don't want this SpanOperation to modify it further.
      def build_span
        Span.new(
          @name,
          duration: duration,
          end_time: @end_time,
          id: @id,
          meta: Core::Utils::SafeDup.frozen_or_dup(meta),
          metrics: Core::Utils::SafeDup.frozen_or_dup(metrics),
          parent_id: @parent_id,
          resource: @resource,
          service: @service,
          start_time: @start_time,
          status: @status,
          type: @type,
          trace_id: @trace_id,
          service_entry: parent.nil? || (service && parent.service != service)
        )
      end

      # Set this span's parent, inheriting any properties not explicitly set.
      # If the parent is nil, set the span as the root span.
      #
      # DEV: This method creates a false expectation that
      # `self.parent.id == self.parent_id`, which is not the case
      # for distributed traces, as the parent Span object does not exist
      # in this application. `#parent_id` is the only reliable parent
      # identifier. We should remove the ability to set a parent Span
      # object in the future.
      def parent=(parent)
        @parent = parent

        if parent.nil?
          @trace_id = @id
          @parent_id = 0
        else
          @trace_id = parent.trace_id
          @parent_id = parent.id
        end
      end

      def duration_marker
        Core::Utils::Time.get_time
      end

      # Used for serialization
      # @return [Integer] in nanoseconds since Epoch
      def start_time_nano
        @start_time.to_i * 1000000000 + @start_time.nsec
      end

      # Used for serialization
      # @return [Integer] in nanoseconds since Epoch
      def duration_nano
        (duration * 1e9).to_i
      end

      # For backwards compatibility
      # TODO: Deprecate and remove these in 2.0.
      alias :span_id :id
      alias :span_type :type
      alias :span_type= :type=
    end
  end
end
