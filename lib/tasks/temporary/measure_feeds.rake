# Temporary tool used to have a rough idea of timings and memory occupation
require "memory_profiler"

class FeedsImportMeasurer
  class << self
    def rss_reader(args)
      call(args, :rss_reader)
    end

    def feeds_import(args)
      call(args, :feeds_import)
    end

    def call(args, importer)
      setup_feeds(num_users: args[:num_users])

      memory_report = MemoryProfiler.report do
        speed_report = Benchmark.measure do
          puts "Importing #{num_users} feeds with #{importer}..."

          case importer
          when :rss_reader
            RssReader.get_all_articles
          when :feeds_import
            Feeds::Import.call
          else
            raise ArgumentError, "unknown importer: #{importer}"
          end
        end

        puts speed_report
      end

      filepath = "/tmp/measure_feeds_#{importer}_#{num_users}_#{Time.current.iso8601}.txt"
      puts "Saving memory profile to #{filepath}..."
      puts memory_report.pretty_print(to_file: filepath)
    end

    def setup_feeds(num_users: nil)
      # we start from no articles in the DB
      Article.delete_all

      # load N feeds
      url = "https://gist.githubusercontent.com/rhymes/be879c36088e571e2400c9715b611b5b/raw/c9cbabe83bdb3ec304300cc60f87b96df4a4e02b/feeds.csv"
      feed_urls = HTTParty.get(url).split

      # remove the CSV header
      feed_urls = feed_urls.drop(1) unless feed_urls.first.starts_with?("http")

      num_users = num_users.present? ? num_users.to_i : User.count

      # update the users with the URLs
      puts "Updating #{num_users} users feeds URLs..."
      index = 0
      User.update_all(feed_url: nil)
      User.limit(num_users).find_each do |user|
        user.update_columns(feed_url: feed_urls[index].strip)
        index += 1
      end
    end
  end
end

namespace :measure_feeds do
  desc "Setup the DB with feeds"
  task :setup, [:num_users] => :environment do |_t, args|
    ActiveRecord::Base.logger = nil
    FeedsImportMeasurer.setup_feeds(num_users: args[:num_users])
  end

  desc "Parses feeds with RssReader class and measures performance and memory occupation"
  task :rss_reader, [:num_users] => :environment do |_t, args|
    ActiveRecord::Base.logger = nil
    Rails.logger.level = :info
    Rails.configuration.log_level = :info

    ### setup step ###
    ### make sure you have enough users in the DB as the number given to the task
    ### eg: SEEDS_MULTIPLIER=10 rails db:seed

    FeedsImportMeasurer.rss_reader(args)
  end

  desc "Parses feeds with Feeds::Import class and measures performance and memory occupation"
  task :feeds_import, [:num_users] => :environment do |_t, args|
    ActiveRecord::Base.logger = nil
    Rails.logger.level = :info
    Rails.configuration.log_level = :info

    ### setup step ###
    ### make sure you have enough users in the DB as the number given to the task
    ### eg: SEEDS_MULTIPLIER=10 rails db:seed

    FeedsImportMeasurer.feeds_import(args)
  end
end
