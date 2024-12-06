# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :test_unit, [:test_unit_args] do |_, args|
    KnapsackPro::Runners::TestUnitRunner.run(args[:test_unit_args])
  end
end
