module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Notifications
          # An ActiveSupport::Notification subscription that wraps events with tracing.
          class Subscription
            attr_accessor \
              :span_name,
              :options

            def initialize(span_name, options, &block)
              raise ArgumentError, 'Must be given a block!' unless block

              @span_name = span_name
              @options = options
              @handler = Handler.new(&block)
              @callbacks = Callbacks.new
            end

            # ActiveSupport 3.x calls this
            def call(name, start, finish, id, payload)
              start_span(name, id, payload, start)
              finish_span(name, id, payload, finish)
            end

            # ActiveSupport 4+ calls this on start
            def start(name, id, payload)
              start_span(name, id, payload)
            end

            # ActiveSupport 4+ calls this on finish
            def finish(name, id, payload)
              finish_span(name, id, payload)
            end

            def before_trace(&block)
              callbacks.add(:before_trace, &block) if block
            end

            def after_trace(&block)
              callbacks.add(:after_trace, &block) if block
            end

            def subscribe(pattern)
              return false if subscribers.key?(pattern)

              subscribers[pattern] = ::ActiveSupport::Notifications.subscribe(pattern, self)
              true
            end

            def unsubscribe(pattern)
              return false unless subscribers.key?(pattern)

              ::ActiveSupport::Notifications.unsubscribe(subscribers[pattern])
              subscribers.delete(pattern)
              true
            end

            def unsubscribe_all
              return false if subscribers.empty?

              subscribers.each_key { |pattern| unsubscribe(pattern) }
              true
            end

            protected

            attr_reader \
              :handler,
              :callbacks

            def start_span(name, id, payload, start = nil)
              # Run callbacks
              callbacks.run(name, :before_trace, id, payload, start)

              # Start a trace
              Tracing.trace(@span_name, **@options).tap do |span|
                # Start span if time is provided
                span.start(start) unless start.nil?
                payload[:datadog_span] = span
              end
            end

            def finish_span(name, id, payload, finish = nil)
              payload[:datadog_span].tap do |span|
                # If no active span, return.
                return nil if span.nil?

                # Run handler for event
                handler.run(span, name, id, payload)

                # Finish the span
                span.finish(finish)

                # Run callbacks
                callbacks.run(name, :after_trace, span, id, payload, finish)
              end
            end

            # Pattern => ActiveSupport:Notifications::Subscribers
            def subscribers
              @subscribers ||= {}
            end

            # Wrapper for subscription handler
            class Handler
              attr_reader :block

              def initialize(&block)
                @block = block
              end

              def run(span, name, id, payload)
                run!(span, name, id, payload)
              rescue StandardError => e
                Datadog.logger.debug(
                  "ActiveSupport::Notifications handler for '#{name}' failed: #{e.class.name} #{e.message}"
                )
              end

              def run!(*args)
                @block.call(*args)
              end
            end

            # Wrapper for subscription callbacks
            class Callbacks
              attr_reader :blocks

              def initialize
                @blocks = {}
              end

              def add(key, &block)
                blocks_for(key) << block if block
              end

              def run(event, key, *args)
                blocks_for(key).each do |callback|
                  begin
                    callback.call(event, key, *args)
                  rescue StandardError => e
                    Datadog.logger.debug(
                      "ActiveSupport::Notifications '#{key}' callback for '#{event}' failed: #{e.class.name} #{e.message}"
                    )
                  end
                end
              end

              private

              def blocks_for(key)
                blocks[key] ||= []
              end
            end
          end
        end
      end
    end
  end
end
