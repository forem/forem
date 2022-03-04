return unless ENV["CI"]

require "csv"
require "rspec/retry"
require "singleton"

class CSVFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending, :close
  HEADERS = ["Description", "File", "Status", "Start Date", "Start Time", "Run Time", "Exception",
             "Backtrace", "Retry #", "Suite Status", "Suite Run Time", "Travis URL", "Travis Branch"].freeze

  def initialize(_output)
    @rows = []
    @suite_start_time = Time.zone.now
    @suite_status = :passed
  end

  def example_pending(notification)
    description = notification.example.metadata[:full_description]
    file = notification.example.metadata[:location]
    status = :pending
    started_at = notification.example.metadata[:execution_result].started_at
    start_date = started_at.strftime("%m-%d-%Y")
    start_time = started_at.strftime("%H-%M-%S.%3N")
    run_time = notification.example.metadata[:execution_result].run_time.round(3)
    @rows << [description, file, status, start_date, start_time, run_time, nil, nil, nil]
  end

  def example_passed(notification)
    description = notification.example.metadata[:full_description]
    file = notification.example.metadata[:location]
    status = :passed
    started_at = notification.example.metadata[:execution_result].started_at
    start_date = started_at.strftime("%m-%d-%Y")
    start_time = started_at.strftime("%H-%M-%S.%3N")
    run_time = notification.example.metadata[:execution_result].run_time.round(3)
    retry_attempt = notification.example.metadata[:retry_attempts]
    @rows << [description, file, status, start_date, start_time, run_time, nil, nil, retry_attempt]
  end

  def example_failed(notification)
    @suite_status = :failed # If we're in here at all it means the entire run will count as failed
    description = notification.example.metadata[:full_description]
    file = notification.example.metadata[:location]
    status = :failed
    started_at = notification.example.metadata[:execution_result].started_at
    start_date = started_at.strftime("%m-%d-%Y")
    start_time = started_at.strftime("%H-%M-%S.%3N")
    run_time = notification.example.metadata[:execution_result].run_time.round(3)
    exception = notification.example.metadata[:execution_result].exception.inspect
    backtrace = notification.example.metadata[:execution_result].exception.backtrace
    backtrace = backtrace.join("   ") if backtrace
    retry_attempt = notification.example.metadata[:retry_attempts]
    @rows << [description, file, status, start_date, start_time, run_time, exception, backtrace, retry_attempt]
  end

  def close(_notification)
    csvs_dir = File.join(Dir.pwd, "tmp", "csvs")
    FileUtils.mkdir_p(csvs_dir)

    timestamp = Time.current.utc.iso8601.tr(":", "-")
    csv_filename = File.join(csvs_dir, "#{timestamp}.csv")

    suite_runtime = (Time.zone.now - @suite_start_time).round(3)

    with_headers = { write_headers: true, headers: HEADERS }
    CSV.open(csv_filename, "w", **with_headers) do |csv|
      (@rows + RSpecRetryFormatterHelper.instance.rows).each do |row|
        row += [@suite_status, suite_runtime, ENV["TRAVIS_BUILD_WEB_URL"], ENV["TRAVIS_BRANCH"]]
        csv << row
      end
    end
  end
end

# This singleton exists so that we can get retry data from the retry_callback in the CSVFormatter
class RSpecRetryFormatterHelper
  include Singleton
  attr_accessor :rows

  def initialize
    @rows = []
  end
end

RSpec.configure do |config|
  config.add_formatter(CSVFormatter)

  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.around :each, :js do |ex|
    ex.run_with_retry retry: 3
  end

  # None of the rspec formatter hooks are invoked in the case of a retry, so the only way to get data
  # from retried tests is to store it in a singleton
  config.retry_callback = proc do |ex|
    description = ex.metadata[:full_description]
    file = ex.metadata[:location]
    status = :failed
    started_at = ex.metadata[:execution_result].started_at
    start_date = started_at.strftime("%m-%d-%Y")
    start_time = started_at.strftime("%H-%M-%S.%3N")
    run_time = (Time.zone.now - started_at).round(3)
    exception = ex.metadata[:retry_exceptions].last.inspect
    backtrace = ex.metadata[:retry_exceptions].last.backtrace
    backtrace = backtrace.join("   ") if backtrace
    retry_attempt = ex.metadata[:retry_attempts]

    RSpecRetryFormatterHelper.instance.rows << [description, file, status, start_date, start_time, run_time,
                                                exception, backtrace, retry_attempt]
  end
end
