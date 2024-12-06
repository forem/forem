require "guard/rspec/command"

module Guard
  class RSpec < Plugin
    class RSpecProcess
      class Failure < RuntimeError
      end

      attr_reader :results, :options

      def initialize(command, formatter_tmp_file, options = {})
        @command = command
        @formatter_tmp_file = formatter_tmp_file
        @results = nil
        @options = options

        @exit_code = _run
        @results = _read_results
      end

      def all_green?
        exit_code.zero?
      end

      private

      def _run
        _with_desired_bundler_env do
          exit_code = _really_run

          msg = "Guard::RSpec: RSpec command %s exited with: %s"
          Compat::UI.debug(format(msg, command, exit_code.inspect))

          unless [0, Command::FAILURE_EXIT_CODE].include?(exit_code)
            msg = "Failed: %s (exit code: %s)"
            raise Failure, format(msg, command.inspect, exit_code.inspect)
          end
          exit_code
        end
      end

      def _really_run
        env = { "GUARD_RSPEC_RESULTS_FILE" => formatter_tmp_file }

        _warn_unless_absolute_path(formatter_tmp_file)

        Compat::UI.debug("Guard::RSpec: results file: #{formatter_tmp_file}")

        pid = Kernel.spawn(env, command) # use spawn to stub in JRuby
        result = ::Process.wait2(pid)
        result.last.exitstatus
      rescue Errno::ENOENT => ex
        raise Failure, "Failed: #{command.inspect} (#{ex})"
      end

      def _read_results
        Results.new(formatter_tmp_file)
      rescue Errno::ENOENT
        msg = "Guard::RSpec cannot open results file: %s. This is likely a bug"\
          "so please report this at"\
          " http://github.com/guard/guard-rspec/issues/new along with as much"\
          "information as possible to reproduce this issue."
        Compat::UI.error(format(msg, formatter_tmp_file.inspect))
        raise
      ensure
        File.delete(formatter_tmp_file) if File.exist?(formatter_tmp_file)
      end

      def _with_desired_bundler_env
        desired_bundler_env = options[:bundler_env]
        if !defined?(::Bundler) || desired_bundler_env == :inherit
          yield
        elsif desired_bundler_env == :clean_env
          ::Bundler.with_clean_env { yield }
        else
          ::Bundler.with_original_env { yield }
        end
      end

      def _warn_unless_absolute_path(formatter_tmp_file)
        return if Pathname(formatter_tmp_file).absolute?

        msg = "Guard::RSpec: The results file %s is not an absolute path."\
          " Please provide an absolute path to avoid issues."
        Compat::UI.warning(format(msg, formatter_tmp_file.inspect))
      end

      attr_reader :command
      attr_reader :exit_code
      attr_reader :formatter_tmp_file
    end
  end
end
