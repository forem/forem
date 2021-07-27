namespace :forem do
  desc "Performs basic setup for new Forem instances"
  # Since we execute this tasks in bin/setup as well as app_initializer:setup
  # everything happening here needs to be idempotent.
  task setup: :environment do
    Rake::Task["navigation_links:create"].invoke
  end

  task health_check_token: :environment do
    puts Settings::General.health_check_token
  end
end
