task award_badges: :environment do
  BadgeRewarder.award_yearly_club_badges
  BadgeRewarder.award_beloved_comment_badges
  BadgeRewarder.award_streak_badge(4)
  BadgeRewarder.award_streak_badge(8)
  BadgeRewarder.award_streak_badge(16)
end

task award_weekly_tag_badges: :environment do
  # Should run once per week.
  # Scheduled "daily" on Heroku Scheduler, should only fully run on Thursday.
  if Time.current.wday == 4
    BadgeRewarder.award_tag_badges
  end
end

# rake award_top_seven_badges["ben jess peter mac liana andy"]
task :award_top_seven_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split(" ")
  puts "Awarding top-7 badges to #{usernames}"
  BadgeRewarder.award_top_seven_badges(usernames)
  puts "Done!"
end

# rake award_contributor_badges["ben jess peter mac liana andy"]
task :award_contributor_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split(" ")
  puts "Awarding dev-contributor badges to #{usernames}"
  BadgeRewarder.award_contributor_badges(usernames)
  puts "Done!"
end

# rake award_fab_five_badges["ben jess peter mac liana andy"]
task :award_fab_five_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split(" ")
  puts "Awarding fab 5 badges to #{usernames}"
  BadgeRewarder.award_fab_five_badges(usernames)
  puts "Done!"
end

# this task is meant to be scheduled daily
task award_contributor_badges_from_github: :environment do
  BadgeRewarder.award_contributor_badges_from_github
end
