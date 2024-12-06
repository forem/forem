require 'simplecov'
require './spec/support/simplecov_quality_formatter'

module SimpleCovHelper
  def start_simple_cov(name)
    SimpleCov.start do
      add_filter '/spec/'
      add_filter '/lib/generators'
      command_name name

      formatters = [SimpleCov::Formatter::QualityFormatter]

      if ENV['CI']
        require 'codeclimate-test-reporter'

        if CodeClimate::TestReporter.run?
          formatters << CodeClimate::TestReporter::Formatter
        end
      end

      formatter SimpleCov::Formatter::MultiFormatter.new(formatters)
    end
  end
end
