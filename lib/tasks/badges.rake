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

# One-time (or occasional) full-history backfill of GitHub contributor badges.
# Walks every merged PR across the repo's history so long-standing contributors
# are awarded, then records the scan marker so the hourly job only scans forward
# from here instead of re-reading years of history every run.
# rake award_contributor_badges_backfill
task award_contributor_badges_backfill: :environment do
  puts "Backfilling GitHub contributor badges across full PR history (this can take a while)..."
  Badges::AwardContributorFromGithub.backfill
  puts "Done! Scanned through #{Settings::General.github_contributor_prs_scanned_through}"
end

# rake award_fab_five_badges["ben jess peter mac liana andy"]
task :award_fab_five_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding fab 5 badges to #{usernames}"
  Badges::AwardFabFive.call(usernames)
  puts "Done!"
end
