namespace :pghero do
  desc "Capture query stats"
  task capture_query_stats: :environment do
    PgHero.capture_query_stats(verbose: true)
  end

  desc "Capture space stats"
  task capture_space_stats: :environment do
    PgHero.capture_space_stats(verbose: true)
  end

  desc "Analyze tables"
  task analyze: :environment do
    PgHero.analyze_all(verbose: true, min_size: ENV["MIN_SIZE_GB"].to_f.gigabytes)
  end

  desc "Autoindex tables"
  task autoindex: :environment do
    PgHero.autoindex_all(verbose: true, create: true)
  end

  desc "Remove old query stats"
  task clean_query_stats: :environment do
    puts "Deleting old query stats..."
    options = {}
    options[:before] = Float(ENV["KEEP_DAYS"]).days.ago if ENV["KEEP_DAYS"].present?
    PgHero.clean_query_stats(**options)
  end

  desc "Remove old space stats"
  task clean_space_stats: :environment do
    puts "Deleting old space stats..."
    options = {}
    options[:before] = Float(ENV["KEEP_DAYS"]).days.ago if ENV["KEEP_DAYS"].present?
    PgHero.clean_space_stats(**options)
  end
end
