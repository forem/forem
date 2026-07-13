namespace :reengagement do
  desc "Build the re-engagement cohort. Usage: rake reengagement:build_cohort[reengagement_2026_q3]"
  task :build_cohort, [:campaign_key] => :environment do |_t, args|
    count = Reengagement.build_cohort(campaign_key: args.fetch(:campaign_key))
    puts "Cohort #{args[:campaign_key]}: #{count} recipients"
  end
end
