# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :cucumber, [:cucumber_args] do |_, args|
    KnapsackPro::Runners::CucumberRunner.run(args[:cucumber_args])
  end
end
