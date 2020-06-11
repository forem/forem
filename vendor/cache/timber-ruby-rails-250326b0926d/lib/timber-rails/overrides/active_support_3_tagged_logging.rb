# Please note, this patch is merely an upgrade, backporting improved tagged logging code
# from newer versions of Rails:
# https://github.com/rails/rails/blob/5-1-stable/activesupport/lib/active_support/tagged_logging.rb
# The behavior of tagged logging will not change in any way.
#
# This patch is specifically for Rails 3. The legacy approach to wrapping the logger in
# ActiveSupport::TaggedLogging is rather poor, hence the reason it was changed entirely
# for Rails 4 and 5. The problem is that ActiveSupport::TaggedLogging is a wrapping
# class that entirely redefines the public API for the logger. As a result, any deviations
# from this API in the logger are not exposed (such as accepting event data as a second argument).
# This is assuming, so we're fixing it here.

begin
  require "active_support/tagged_logging"

  # Instead of patching the class we're pulling the code from Rails master. This brings in
  # a number of improvements while also addressing the issue above.
  if ActiveSupport::TaggedLogging.instance_of?(Class)
    ActiveSupport.send(:remove_const, :TaggedLogging)

    require "active_support/core_ext/module/delegation"
    require "active_support/core_ext/object/blank"
    require "logger"

    module ActiveSupport
      # Wraps any standard Logger object to provide tagging capabilities.
      #
      #   logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
      #   logger.tagged('BCX') { logger.info 'Stuff' }                            # Logs "[BCX] Stuff"
      #   logger.tagged('BCX', "Jason") { logger.info 'Stuff' }                   # Logs "[BCX] [Jason] Stuff"
      #   logger.tagged('BCX') { logger.tagged('Jason') { logger.info 'Stuff' } } # Logs "[BCX] [Jason] Stuff"
      #
      # This is used by the default Rails.logger as configured by Railties to make
      # it easy to stamp log lines with subdomains, request ids, and anything else
      # to aid debugging of multi-user production applications.
      module TaggedLogging
        module Formatter # :nodoc:
          # This method is invoked when a log event occurs.
          def call(severity, timestamp, progname, msg)
            super(severity, timestamp, progname, "#{tags_text}#{msg}")
          end

          def tagged(*tags)
            new_tags = push_tags(*tags)
            yield self
          ensure
            pop_tags(new_tags.size)
          end

          def push_tags(*tags)
            tags.flatten.reject(&:blank?).tap do |new_tags|
              current_tags.concat new_tags
            end
          end

          def pop_tags(size = 1)
            current_tags.pop size
          end

          def clear_tags!
            current_tags.clear
          end

          def current_tags
            # We use our object ID here to avoid conflicting with other instances
            thread_key = @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}".freeze
            Thread.current[thread_key] ||= []
          end

          def tags_text
            tags = current_tags
            if tags.any?
              tags.collect { |tag| "[#{tag}] " }.join
            end
          end
        end

        # Simple formatter which only displays the message.
        class SimpleFormatter < ::Logger::Formatter
          # This method is invoked when a log event occurs
          def call(severity, timestamp, progname, msg)
            "#{String === msg ? msg : msg.inspect}\n"
          end
        end

        def self.new(logger)
          if logger.respond_to?(:formatter=) && logger.respond_to?(:formatter)
            # Ensure we set a default formatter so we aren't extending nil!
            logger.formatter ||= SimpleFormatter.new
            logger.formatter.extend Formatter
          end

          logger.extend(self)
        end

        delegate :push_tags, :pop_tags, :clear_tags!, to: :formatter

        def tagged(*tags)
          formatter.tagged(*tags) { yield self }
        end

        def flush
          clear_tags!
          super if defined?(super)
        end
      end
    end
  end

rescue Exception
end