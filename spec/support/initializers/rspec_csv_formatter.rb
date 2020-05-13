require "csv"

class CSVFormatter < RSpec::Core::Formatters::JsonFormatter
  RSpec::Core::Formatters.register self

  def close(_notification)
    headers = ["Spec", "File", "Status", "Run Time", "Exception"]
    headers += ["Travis Branch", "Travis URL"]
    with_headers = { write_headers: true, headers: headers }

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
    tmp_dir = File.join(Dir.pwd, "tmp")
    FileUtils.mkdir(tmp_dir) unless File.directory?(tmp_dir)

    csvs_dir = File.join(tmp_dir, "csvs")
    FileUtils.mkdir(csvs_dir) unless File.directory?(csvs_dir)

    timestamp = DateTime.now.utc.strftime("D%Y-%m-%dT%H-%M-%S")
    csv_filename = File.join(csvs_dir, "#{ENV['TRAVIS_BUILD_NUMBER']}-#{timestamp}.csv")

    config.add_formatter(CSVFormatter, csv_filename)
  end
end
