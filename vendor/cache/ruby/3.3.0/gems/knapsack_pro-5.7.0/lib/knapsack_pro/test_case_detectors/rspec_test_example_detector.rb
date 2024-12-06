# frozen_string_literal: true

module KnapsackPro
  module TestCaseDetectors
    class RSpecTestExampleDetector
      def generate_json_report
        require 'rspec/core'

        cli_format =
          if Gem::Version.new(::RSpec::Core::Version::STRING) < Gem::Version.new('3.6.0')
            require_relative '../formatters/rspec_json_formatter'
            ['--format', KnapsackPro::Formatters::RSpecJsonFormatter.to_s]
          else
            ['--format', 'json']
          end

        ensure_report_dir_exists
        remove_old_json_report

        test_file_entities = slow_test_files

        if test_file_entities.empty?
          no_examples_json = { examples: [] }.to_json
          File.write(report_path, no_examples_json)
          return
        end

        cli_args = cli_format + [
          '--dry-run',
          '--out', report_path,
          '--default-path', test_dir,
        ] + KnapsackPro::TestFilePresenter.paths(test_file_entities)
        options = ::RSpec::Core::ConfigurationOptions.new(cli_args)
        exit_code = ::RSpec::Core::Runner.new(options).run($stderr, $stdout)
        if exit_code != 0
          debug_cmd = ([
            'bundle exec rspec',
          ] + cli_args).join(' ')

          KnapsackPro.logger.error('-'*10 + ' START of actionable error message ' + '-'*50)
          KnapsackPro.logger.error('RSpec (with a dry-run option) had a problem generating the report with test examples for the slow test files. Here is what you can do:')

          KnapsackPro.logger.error("a) Please look for an error message from RSpec in the output above or below. If you don't see anything, that is fine. Sometimes RSpec does not produce any errors in the output.")

          KnapsackPro.logger.error("b) Check if RSpec generated the report file #{report_path}. If the report exists, it may contain an error message. Here is a preview of the report file:")
          KnapsackPro.logger.error(report_content || 'N/A')

          KnapsackPro.logger.error('c) To reproduce the error manually, please run the following RSpec command. This way, you can find out what is causing the error. Please ensure you run the command in the same environment where the error occurred. For instance, if the error happens on the CI server, you should run the command in the CI environment:')
          KnapsackPro.logger.error(debug_cmd)

          KnapsackPro.logger.error('-'*10 + ' END of actionable error message ' + '-'*50)

          raise 'There was a problem while generating test examples for the slow test files. Please read the actionable error message above.'
        end
      end

      def test_file_example_paths
        raise "No report found at #{report_path}" unless File.exist?(report_path)

        json_report = File.read(report_path)
        hash_report = JSON.parse(json_report)
        hash_report
          .fetch('examples')
          .map { |e| e.fetch('id') }
          .map { |path_with_example_id| test_file_hash_for(path_with_example_id) }
      end

      def slow_test_files
        if KnapsackPro::Config::Env.slow_test_file_pattern
          KnapsackPro::TestFileFinder.slow_test_files_by_pattern(adapter_class)
        else
          # read slow test files from JSON file on disk that was generated
          # by lib/knapsack_pro/base_allocator_builder.rb
          KnapsackPro::SlowTestFileDeterminer.read_from_json_report
        end
      end

      private

      def report_dir
        "#{KnapsackPro::Config::TempFiles::TEMP_DIRECTORY_PATH}/test_case_detectors/rspec"
      end

      def report_path
        "#{report_dir}/rspec_dry_run_json_report_node_#{KnapsackPro::Config::Env.ci_node_index}.json"
      end

      def report_content
        File.read(report_path) if File.exist?(report_path)
      end

      def adapter_class
        KnapsackPro::Adapters::RSpecAdapter
      end

      def test_dir
        KnapsackPro::Config::Env.test_dir || KnapsackPro::TestFilePattern.test_dir(adapter_class)
      end

      def test_file_pattern
        KnapsackPro::TestFilePattern.call(adapter_class)
      end

      def ensure_report_dir_exists
        KnapsackPro::Config::TempFiles.ensure_temp_directory_exists!
        FileUtils.mkdir_p(report_dir)
      end

      def remove_old_json_report
        File.delete(report_path) if File.exist?(report_path)
      end

      def test_file_hash_for(test_file_path)
        {
          'path' => TestFileCleaner.clean(test_file_path)
        }
      end
    end
  end
end
