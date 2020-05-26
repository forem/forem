namespace :app do
  desc "Prepare Application on Boot Up"
  task setup: :environment do
    puts "\n== Preparing Elasticsearch =="
    Rake::Task["search:setup"].execute

    puts "\n== Preparing database =="
    begin
      Rake::Task["db:migrate"].execute
    rescue ActiveRecord::NoDatabaseError
      puts "\n== Creating and Seeding database =="
      Rake::Task["db:create"].execute
      Rake::Task["db:schema:load"].execute
      Rake::Task["db:seed"].execute
    end

    puts "\n== Updating Data =="
    Rake::Task["data_updates:enqueue_data_update_worker"].execute
  end
end
