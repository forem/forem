# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :rspec, [:rspec_args] do |_, args|
    KnapsackPro::Runners::RSpecRunner.run(args[:rspec_args])
  end

  desc "Generate JSON report for test suite based on default test pattern or based on defined pattern with ENV vars"
  task :rspec_test_example_detector do
    # ignore the `SPEC_OPTS` options to not affect RSpec execution within this rake task
    ENV.delete('SPEC_OPTS')

    detector = KnapsackPro::TestCaseDetectors::RSpecTestExampleDetector.new
    detector.generate_json_report
  end
end
