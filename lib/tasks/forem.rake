namespace :forem do
  desc "Performs basic setup for new Forem instances"
  # Since we execute this tasks in bin/setup as well as app_initializer:setup
  # everything happening here needs to be idempotent.
  task setup: :environment do
    # NOTE: There are currently no tasks here. This will change as soon as we
    # add/update the task for seeding navigation links to support RFC #237.
  end

  task health_check_token: :environment do
    puts Settings::General.health_check_token
  end
end
