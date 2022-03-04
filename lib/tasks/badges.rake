# rake award_top_seven_badges["ben jess peter mac liana andy"]
task :award_top_seven_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding top-7 badges to #{usernames}"
  Badges::AwardTopSeven.call(usernames)
  puts "Done!"
end

# rake award_contributor_badges["ben jess peter mac liana andy"]
task :award_contributor_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding dev-contributor badges to #{usernames}"
  Badges::AwardContributor.call(usernames)
  puts "Done!"
end

# rake award_fab_five_badges["ben jess peter mac liana andy"]
task :award_fab_five_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding fab 5 badges to #{usernames}"
  Badges::AwardFabFive.call(usernames)
  puts "Done!"
end
