module Feeds
  class Import
    def self.call
      new.call
    end

    # TODO: add `users` param
    def initialize
      @users = User.where.not(feed_url: [nil, ""])
      @num_workers = 4
    end

    # 1. concurrently fetch feeds from the internet in batches
    # 2. per each batch build articles
    # 3. update `feed_fetched_at` for each user in the batch
    def call
      users.find_in_batches(batch_size: 100) do |batch_of_users|
        feeds_per_user_id = fetch_feeds(batch_of_users)
        puts "feeds_per_user_id.length: #{feeds_per_user_id.length}"

        feedjira_objects = parse_feeds(feeds_per_user_id)
        puts "feedjira_objects.length: #{feedjira_objects.length}"

        # NOTE: doing this sequentially to avoid locking problems with the DB
        # and unnecessary conflicts
        articles = feedjira_objects.map do |user_id, feed|
          # TODO: replace `feed` with `feed.url` as `RssReader::Assembler`
          # only actually needs feed.url
          user = batch_of_users.detect { |user| user.id == user_id }
          create_articles_from_user_feed(user, feed)
        end
        puts "articles.length: #{articles.flatten.length}"
      end
    end

    private

    attr_reader :users, :num_workers

    # TODO: put this in separate service object
    def fetch_feeds(batch_of_users)
      data = batch_of_users.pluck(:id, :feed_url)

      result = Parallel.map(data, in_threads: num_workers) do |user_id, url|
        response = HTTParty.get(url.strip, timeout: 10)

        [user_id, response.body]
      rescue Exception
        # TODO: add exception handling
        # For example, we should stop pulling feeds that return 404 and disable them?
        nil
      end

      Hash[result.compact]
    end

    # TODO: put this in separate service object
    def parse_feeds(feeds_per_user_id)
      result = Parallel.map(feeds_per_user_id, in_threads: num_workers) do |user_id, feed_xml|
        parsed_feed = Feedjira.parse(feed_xml)

        [user_id, parsed_feed]
      rescue Feedjira::NoParserAvailable
        # TODO: add exception handling
        nil
      end

      Hash[result.compact]
    end

    # TODO: currently this is exactly as in RSSReader, but we might find
    # avenues for optimization, like:
    # 1. why are we sending N exists query to the DB, one per each item, can we fetch them all?
    def create_articles_from_user_feed(user, feed)
      articles = []

      feed.entries.reverse_each do |item|
        next if medium_reply?(item) || article_exists?(user, item)

        feed_source_url = item.url.strip.split("?source=")[0]
        article = Article.create!(
          feed_source_url: feed_source_url,
          user_id: user.id,
          published_from_feed: true,
          show_comments: true,
          body_markdown: RssReader::Assembler.call(item, user, feed, feed_source_url),
          organization_id: nil,
        )
        # Slack::Messengers::ArticleFetchedFeed.call(article: article)

        articles.append(article)
      rescue Exception
        # TODO: add exception handling

        next
      end

      articles
    end

    def get_host_without_www(url)
      url = "http://#{url}" if URI.parse(url).scheme.nil?
      host = URI.parse(url).host.downcase
      host.start_with?("www.") ? host[4..] : host
    end

    def medium_reply?(item)
      get_host_without_www(item.url.strip) == "medium.com" &&
        !item[:categories] &&
        content_is_not_the_title?(item)
    end

    def content_is_not_the_title?(item)
      # [[:space:]] removes all whitespace, including unicode ones.
      content = item.content.gsub(/[[:space:]]/, " ")
      title = item.title.delete("…")
      content.include?(title)
    end

    def article_exists?(user, item)
      title = item.title.strip.gsub('"', '\"')
      feed_source_url = item.url.strip.split("?source=")[0]
      relation = user.articles
      relation.where(title: title).or(relation.where(feed_source_url: feed_source_url)).exists?
    end
  end
end
