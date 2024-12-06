# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :spinach, [:spinach_args] do |_, args|
    KnapsackPro::Runners::SpinachRunner.run(args[:spinach_args])
  end
end
