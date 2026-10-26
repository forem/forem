require "csv"
require "fileutils"
require "time"

class RSpecRetryCsvReport
  HEADERS = ["Description", "File", "Status", "Start Date", "Start Time", "Run Time", "Exception",
             "Backtrace", "Retry #", "Suite Status", "Suite Run Time", "Travis URL", "Travis Branch"].freeze

  def self.write(rows:, suite_status:, suite_runtime:,
                 directory: File.join(Dir.pwd, "tmp", "rspec-retries"),
                 timestamp: Time.current.utc, process_id: Process.pid)
    return if rows.empty?

    FileUtils.mkdir_p(directory)
    filename = File.join(directory, "#{timestamp.iso8601(6).tr(':', '-')}-#{process_id}.csv")

    CSV.open(filename, "w", write_headers: true, headers: HEADERS) do |csv|
      rows.each do |row|
        csv << (row + [suite_status, suite_runtime, ENV.fetch("TRAVIS_BUILD_WEB_URL", nil),
                       ENV.fetch("TRAVIS_BRANCH", nil)])
      end
    end

    filename
  end
end
