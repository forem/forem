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
  if Badges::AwardContributorFromGithub.backfill
    puts "Done! Scanned through #{Settings::General.github_contributor_prs_scanned_through}"
  else
    abort "Backfill incomplete due to GitHub API errors or rate limiting. Re-run to continue."
  end
end

# rake award_fab_five_badges["ben jess peter mac liana andy"]
task :award_fab_five_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split
  puts "Awarding fab 5 badges to #{usernames}"
  Badges::AwardFabFive.call(usernames)
  puts "Done!"
end

# Full-history backfill of the 4/8/16 week writing streak badges. Idempotent,
# so it is safe to re-run after creating streak badges that did not exist when
# the BackfillWritingStreakBadges data update script ran.
# rake award_streak_badges_backfill
task award_streak_badges_backfill: :environment do
  puts "Backfilling writing streak badges across full publishing history..."
  begin
    missing = Badges::AwardStreak.backfill
  rescue Badges::AwardStreak::IncompleteError => e
    abort "Backfill incomplete, some awards failed: #{e.message}. Re-run to retry the remaining users."
  end
  missing.each do |weeks|
    slugs = Badges::AwardStreak.new(weeks: weeks).candidate_slugs.join(" or ")
    puts "Skipped #{weeks} week streak: no badge with slug #{slugs}"
  end
  puts "Done!"
end
