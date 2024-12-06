require_relative "rspec_defaults"

module Guard
  # Just a wrapper class for the results file filename
  class RSpecFormatterResultsPath
    WIKI_ENV_WARN_URL =
      "https://github.com/guard/guard-rspec/wiki/Warning:-no-environment".
      freeze

    NO_ENV_WARNING_MSG =
      "no environment passed - see #{WIKI_ENV_WARN_URL}".freeze

    NO_RESULTS_VALUE_MSG =
      ":results_file value unknown (using defaults)".freeze

    attr_reader :path

    def initialize
      path = ENV["GUARD_RSPEC_RESULTS_FILE"]
      if path.nil?
        STDERR.puts("Guard::RSpec: Warning: #{NO_ENV_WARNING_MSG}\n" \
                    "Guard::RSpec: Warning: #{NO_RESULTS_VALUE_MSG}")
        path = RSpecDefaults::TEMPORARY_FILE_PATH
      end

      @path = File.expand_path(path)
    end
  end
end
