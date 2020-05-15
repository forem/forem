require "csv"

class CSVFormatter < RSpec::Core::Formatters::JsonFormatter
  RSpec::Core::Formatters.register self
  HEADERS = ["Spec", "File", "Status", "Run Time", "Exception", "Travis Branch", "Travis URL"].freeze

  def close(_notification)
    with_headers = { write_headers: true, headers: HEADERS }

    CSV.open(output.path, "w", with_headers) do |csv|
      @output_hash[:examples].map do |ex|
        file_path = "#{ex[:file_path]}:#{ex[:line_number]}"
        row = [ex[:full_description], file_path, ex[:status], ex[:run_time], ex[:exception]]
        row += [ENV["TRAVIS_BRANCH"], ENV["TRAVIS_BUILD_WEB_URL"]]
        csv << row
      end
    end
  end
end

if ENV["TRAVIS"]
  RSpec.configure do |config|
    csvs_dir = File.join(Dir.pwd, "tmp", "csvs")
    FileUtils.mkdir_p(csvs_dir)

    timestamp = Time.current.utc.iso8601
    csv_filename = File.join(csvs_dir, "#{timestamp}.csv")

    config.add_formatter(CSVFormatter, csv_filename)
  end
end
