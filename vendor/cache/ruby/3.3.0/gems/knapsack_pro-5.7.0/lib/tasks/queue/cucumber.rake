# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  namespace :queue do
    task :cucumber, [:cucumber_args] do |_, args|
      Kernel.system("RAILS_ENV=test RACK_ENV=test #{$PROGRAM_NAME} 'knapsack_pro:queue:cucumber_go[#{args[:cucumber_args]}]'")
      exitstatus = $?.exitstatus
      if exitstatus.nil?
        puts 'Something went wrong. Most likely, the process has been killed. Knapsack Pro has been terminated.'
        Kernel.exit(1)
      else
        Kernel.exit(exitstatus)
      end
    end

    task :cucumber_go, [:cucumber_args] do |_, args|
      KnapsackPro::Runners::Queue::CucumberRunner.run(args[:cucumber_args])
    end
  end
end
