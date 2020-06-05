namespace :app_initializer do
  desc "Prepare Application on Boot Up"
  task setup: :environment do
    puts "\n== Preparing Elasticsearch =="
    Rake::Task["search:setup"].execute

    puts "\n== Preparing database =="
    system('bin/rails db:prepare')

    puts "\n== Updating Data =="
    Rake::Task["data_updates:enqueue_data_update_worker"].execute

    SiteConfig.health_check_token ||= SecureRandom.hex(10)
  end
end
