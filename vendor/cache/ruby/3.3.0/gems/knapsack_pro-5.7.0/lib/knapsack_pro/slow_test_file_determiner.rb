# frozen_string_literal: true

module KnapsackPro
  class SlowTestFileDeterminer
    TIME_THRESHOLD_PER_CI_NODE = 0.7 # 70%

    # test_files: { 'path' => 'a_spec.rb', 'time_execution' => 0.0 }
    # time_execution: of build distribution (total time of CI build run)
    def self.call(test_files, time_execution)
      time_threshold = (time_execution / KnapsackPro::Config::Env.ci_node_total) * TIME_THRESHOLD_PER_CI_NODE

      test_files.select do |test_file|
        time_execution = test_file.fetch('time_execution')
        time_execution >= time_threshold && time_execution > 0
      end
    end

    def self.save_to_json_report(test_files)
      KnapsackPro::Config::TempFiles.ensure_temp_directory_exists!
      FileUtils.mkdir_p(report_dir)
      File.write(report_path, test_files.to_json)
    end

    def self.read_from_json_report
      raise "The report with slow test files has not been generated yet. If you have enabled split by test cases #{KnapsackPro::Urls::SPLIT_BY_TEST_EXAMPLES} and you see this error it means that your tests accidentally cleaned up the .knapsack_pro directory. Please do not remove this directory during tests runtime!" unless File.exist?(report_path)
      slow_test_files_json_report = File.read(report_path)
      JSON.parse(slow_test_files_json_report)
    end

    private

    def self.report_path
      "#{report_dir}/slow_test_files_node_#{KnapsackPro::Config::Env.ci_node_index}.json"
    end

    def self.report_dir
      "#{KnapsackPro::Config::TempFiles::TEMP_DIRECTORY_PATH}/slow_test_file_determiner"
    end
  end
end
