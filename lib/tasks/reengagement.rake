namespace :reengagement do
  desc "Build the re-engagement cohort. Usage: rake reengagement:build_cohort[reengagement_2026_q3]"
  task :build_cohort, [:campaign_key] => :environment do |_t, args|
    count = Reengagement.build_cohort(campaign_key: args.fetch(:campaign_key))
    puts "Cohort #{args[:campaign_key]}: #{count} recipients"
  end

  desc "Send campaign. Usage: rake reengagement:send[EMAIL_ID,campaign_key]"
  task :send, %i[email_id campaign_key] => :environment do |_t, args|
    Reengagement.enqueue_send(email_id: args.fetch(:email_id).to_i, campaign_key: args.fetch(:campaign_key))
    puts "Enqueued sends for #{args[:campaign_key]}"
  end

  desc "Prune non-responders. Usage: rake reengagement:prune[campaign_key] CONFIRM=YES"
  task :prune, [:campaign_key] => :environment do |_t, args|
    abort "Refusing to prune without CONFIRM=YES" unless ENV["CONFIRM"] == "YES"

    Reengagement.enqueue_prune(campaign_key: args.fetch(:campaign_key))
    puts "Enqueued prune for #{args[:campaign_key]}"
  end
end
