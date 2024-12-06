namespace :blazer do
  desc "run checks"
  task :run_checks, [:schedule] => :environment do |_, args|
    Blazer.run_checks(schedule: args[:schedule] || ENV["SCHEDULE"])
  end

  desc "send failing checks"
  task send_failing_checks: :environment do
    Blazer.send_failing_checks
  end

  desc "archive queries"
  task archive_queries: :environment do
    begin
      Blazer.archive_queries
    rescue => e
      abort e.message
    end
  end
end
