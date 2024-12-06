# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :minitest, [:minitest_args] do |_, args|
    KnapsackPro::Runners::MinitestRunner.run(args[:minitest_args])
  end
end
