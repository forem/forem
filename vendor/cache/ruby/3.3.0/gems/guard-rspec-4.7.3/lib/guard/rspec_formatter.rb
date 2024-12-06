# NOTE: This class only exists for RSpec and should not be used by
# other classes in this project!

require "pathname"
require "fileutils"

require "rspec"
require "rspec/core/formatters/base_formatter"

require_relative "rspec_formatter_results_path"

module Guard
  class RSpecFormatter < ::RSpec::Core::Formatters::BaseFormatter
    UNSUPPORTED_PATTERN =
      "Your RSpec.configuration.pattern uses characters "\
      "unsupported by your Ruby version (File::FNM_EXTGLOB is undefined)".freeze

    class Error < RuntimeError
      class UnsupportedPattern < Error
        def initialize(msg = UNSUPPORTED_PATTERN)
          super
        end
      end
    end

    def self.rspec_3?
      ::RSpec::Core::Version::STRING.split(".").first == "3"
    end

    if rspec_3?
      ::RSpec::Core::Formatters.register self, :dump_summary, :example_failed

      def example_failed(failure)
        examples.push failure.example
      end

      def examples
        @examples ||= []
      end
    end

    class << self
      # rspec issue https://github.com/rspec/rspec-core/issues/793
      def extract_spec_location(metadata)
        root_metadata = metadata
        location = metadata[:location]

        until spec_path?(location)
          unless (metadata = _extract_group(metadata))
            STDERR.puts "no spec file location in #{root_metadata.inspect}"
            return root_metadata[:location]
          end

          # rspec issue https://github.com/rspec/rspec-core/issues/1243
          location = first_colon_separated_entry(metadata[:location])
        end

        location
      end

      def spec_path?(path)
        pattern = ::RSpec.configuration.pattern

        flags = supported_fnmatch_flags(pattern)
        path ||= ""
        path = path.sub(/:\d+\z/, "")
        path = Pathname.new(path).cleanpath.to_s
        stripped = "{#{pattern.gsub(/\s*,\s*/, ',')}}"
        File.fnmatch(stripped, path, flags)
      end

      private

      def first_colon_separated_entry(entries)
        (entries || "").split(":").first
      end

      def supported_fnmatch_flags(pattern)
        flags = File::FNM_PATHNAME | File::FNM_DOTMATCH

        # ruby >= 2
        return flags |= File::FNM_EXTGLOB if File.const_defined?(:FNM_EXTGLOB)

        raise Error::UnsupportedPattern if pattern =~ /[{}]/

        flags
      end

      def _extract_group(metadata)
        metadata[:parent_example_group] || metadata[:example_group]
      end
    end

    def dump_summary(*args)
      return write_summary(*args) unless self.class.rspec_3?

      notification = args[0]
      write_summary(
        notification.duration,
        notification.example_count,
        notification.failure_count,
        notification.pending_count
      )
    end

    private

    # Write summary to temporary file for runner
    def write_summary(duration, total, failures, pending)
      _write do |f|
        f.puts _message(total, failures, pending, duration)
        f.puts _failed_paths.join("\n") if failures > 0
      end
    end

    def _write(&block)
      file = RSpecFormatterResultsPath.new.path
      if ENV['GUARD_RSPEC_DEBUGGING'] == '1'
        msg = "Guard::RSpec: using results file: #{file.inspect}"
        STDERR.puts format(msg, file)
      end
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w", &block)
    end

    def _failed_paths
      klass = self.class
      failed = examples.select { |example| _status_failed?(example) }
      failed.map { |e| klass.extract_spec_location(e.metadata) }.sort.uniq
    end

    def _message(example_count, failure_count, pending_count, duration)
      message = "#{example_count} examples, #{failure_count} failures"
      message << " (#{pending_count} pending)" if pending_count > 0
      message << " in #{duration.round(4)} seconds"
      message
    end

    def _status_failed?(example)
      if self.class.rspec_3?
        example.execution_result.status.to_s == "failed"
      else
        example.execution_result[:status].to_s == "failed"
      end
    end
  end
end
