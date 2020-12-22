# rake award_top_seven_badges["ben jess peter mac liana andy"]
task :award_top_seven_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding top-7 badges to #{usernames}"
  BadgeRewarder.award_top_seven_badges(usernames)
  puts "Done!"
end

# rake award_contributor_badges["ben jess peter mac liana andy"]
task :award_contributor_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding dev-contributor badges to #{usernames}"
  BadgeRewarder.award_contributor_badges(usernames)
  puts "Done!"
end

# rake award_fab_five_badges["ben jess peter mac liana andy"]
task :award_fab_five_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding fab 5 badges to #{usernames}"
  BadgeRewarder.award_fab_five_badges(usernames)
  puts "Done!"
end
