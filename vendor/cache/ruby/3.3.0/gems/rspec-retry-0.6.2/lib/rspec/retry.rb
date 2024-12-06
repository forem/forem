require 'rspec/core'
require 'rspec/retry/version'
require 'rspec_ext/rspec_ext'

module RSpec
  class Retry
    def self.setup
      RSpec.configure do |config|
        config.add_setting :verbose_retry, :default => false
        config.add_setting :default_retry_count, :default => 1
        config.add_setting :default_sleep_interval, :default => 0
        config.add_setting :exponential_backoff, :default => false
        config.add_setting :clear_lets_on_failure, :default => true
        config.add_setting :display_try_failure_messages, :default => false

        # retry based on example metadata
        config.add_setting :retry_count_condition, :default => ->(_) { nil }

        # If a list of exceptions is provided and 'retry' > 1, we only retry if
        # the exception that was raised by the example is NOT in that list. Otherwise
        # we ignore the 'retry' value and fail immediately.
        #
        # If no list of exceptions is provided and 'retry' > 1, we always retry.
        config.add_setting :exceptions_to_hard_fail, :default => []

        # If a list of exceptions is provided and 'retry' > 1, we only retry if
        # the exception that was raised by the example is in that list. Otherwise
        # we ignore the 'retry' value and fail immediately.
        #
        # If no list of exceptions is provided and 'retry' > 1, we always retry.
        config.add_setting :exceptions_to_retry, :default => []

        # Callback between retries
        config.add_setting :retry_callback, :default => nil

        config.around(:each) do |ex|
          ex.run_with_retry
        end
      end
    end

    attr_reader :context, :ex

    def initialize(ex, opts = {})
      @ex = ex
      @ex.metadata.merge!(opts)
      current_example.attempts ||= 0
    end

    def current_example
      @current_example ||= RSpec.current_example
    end

    def retry_count
      [
          (
          ENV['RSPEC_RETRY_RETRY_COUNT'] ||
              ex.metadata[:retry] ||
              RSpec.configuration.retry_count_condition.call(ex) ||
              RSpec.configuration.default_retry_count
          ).to_i,
          1
      ].max
    end

    def attempts
      current_example.attempts ||= 0
    end

    def attempts=(val)
      current_example.attempts = val
    end

    def clear_lets
      !ex.metadata[:clear_lets_on_failure].nil? ?
          ex.metadata[:clear_lets_on_failure] :
          RSpec.configuration.clear_lets_on_failure
    end

    def sleep_interval
      if ex.metadata[:exponential_backoff]
          2**(current_example.attempts-1) * ex.metadata[:retry_wait]
      else
          ex.metadata[:retry_wait] ||
              RSpec.configuration.default_sleep_interval
      end
    end

    def exceptions_to_hard_fail
      ex.metadata[:exceptions_to_hard_fail] ||
          RSpec.configuration.exceptions_to_hard_fail
    end

    def exceptions_to_retry
      ex.metadata[:exceptions_to_retry] ||
          RSpec.configuration.exceptions_to_retry
    end

    def verbose_retry?
      RSpec.configuration.verbose_retry?
    end

    def display_try_failure_messages?
      RSpec.configuration.display_try_failure_messages?
    end

    def run
      example = current_example

      loop do
        if attempts > 0
          RSpec.configuration.formatters.each { |f| f.retry(example) if f.respond_to? :retry }
          if verbose_retry?
            message = "RSpec::Retry: #{ordinalize(attempts + 1)} try #{example.location}"
            message = "\n" + message if attempts == 1
            RSpec.configuration.reporter.message(message)
          end
        end

        example.metadata[:retry_attempts] = self.attempts
        example.metadata[:retry_exceptions] ||= []

        example.clear_exception
        ex.run

        self.attempts += 1

        break if example.exception.nil?

        example.metadata[:retry_exceptions] << example.exception

        break if attempts >= retry_count

        if exceptions_to_hard_fail.any?
          break if exception_exists_in?(exceptions_to_hard_fail, example.exception)
        end

        if exceptions_to_retry.any?
          break unless exception_exists_in?(exceptions_to_retry, example.exception)
        end

        if verbose_retry? && display_try_failure_messages?
          if attempts != retry_count
            exception_strings =
              if ::RSpec::Core::MultipleExceptionError::InterfaceTag === example.exception
                example.exception.all_exceptions.map(&:to_s)
              else
                [example.exception.to_s]
              end

            try_message = "\n#{ordinalize(attempts)} Try error in #{example.location}:\n#{exception_strings.join "\n"}\n"
            RSpec.configuration.reporter.message(try_message)
          end
        end

        example.example_group_instance.clear_lets if clear_lets

        # If the callback is defined, let's call it
        if RSpec.configuration.retry_callback
          example.example_group_instance.instance_exec(example, &RSpec.configuration.retry_callback)
        end

        sleep sleep_interval if sleep_interval.to_f > 0
      end
    end

    private

    # borrowed from ActiveSupport::Inflector
    def ordinalize(number)
      if (11..13).include?(number.to_i % 100)
        "#{number}th"
      else
        case number.to_i % 10
        when 1; "#{number}st"
        when 2; "#{number}nd"
        when 3; "#{number}rd"
        else    "#{number}th"
        end
      end
    end

    def exception_exists_in?(list, exception)
      list.any? do |exception_klass|
        exception.is_a?(exception_klass) || exception_klass === exception
      end
    end
  end
end

RSpec::Retry.setup
