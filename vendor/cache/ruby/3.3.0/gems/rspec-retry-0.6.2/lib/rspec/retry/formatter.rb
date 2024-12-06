require 'rspec/core/formatters/base_text_formatter'

class RSpec::Retry::Formatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register self, :example_passed

  def initialize(output)
    super(output)
    @tries = Hash.new { |h, k| h[k] = { successes: 0, tries: 0 } }
  end

  def seed(_); end

  def message(_message); end

  def close(_); end

  def dump_failures(_); end

  def dump_pending(_); end

  def dump_summary(notification)
    summary = "\nRSpec Retry Summary:\n"
    @tries.each do |key, retry_data|
      next if retry_data[:successes] < 1 || retry_data[:tries] <= 1
      summary += "\t#{key.location}: #{key.full_description}: passed at attempt #{retry_data[:tries]}\n"
    end
    retried = @tries.count { |_, v| v[:tries] > 1  && v[:successes] > 0 }
    summary += "\n\t#{retried} of #{notification.example_count} tests passed with retries.\n"
    summary += "\t#{notification.failure_count} tests failed all retries.\n"
    output.puts summary
  end

  def example_passed(notification)
    increment_success notification.example
  end

  def retry(example)
    increment_tries example
  end

  private

  def increment_success(example)
    # debugger
    previous = @tries[example]
    @tries[example] = {
      successes: previous[:successes] + 1, tries: previous[:tries] + 1 }
  end

  def increment_tries(example)
    # debugger
    previous = @tries[example]
    @tries[example] = {
      successes: previous[:successes], tries: previous[:tries] + 1 }
  end
end
