module Feeds
  # Responsible for fetching RSS feeds for multiple users.
  #
  # @see Feeds::Import.call
  class Import
    # Fetch the feeds for the given users (with some filtering based on internal business logic).
    #
    # @param users_scope [ActiveRecord::Relation<User>] the initial scope for determining the users
    #        whose feeds we'll be fetching.
    #
    # @param earlier_than [NilClass, ActiveSupport::TimeWithZone] when given, use this to further
    #        filter the user's who's articles we'll fetch.  That is to say, we won't fetch anyone's
    #        feeds who's last fetch time was after our earlier_than parameter.
    #
    # @return [Integer] count of total articles fetched.
    def self.call(users_scope: User, earlier_than: nil)
      new(users_scope: users_scope, earlier_than: earlier_than).call
    end

    def initialize(users_scope: User, earlier_than: nil)
      @earlier_than = earlier_than
      @users = filter_users_from(users_scope: users_scope, earlier_than: earlier_than)

      # NOTE: should these be configurable? Currently they are the result of empiric
      # tests trying to find a balance between memory occupation and speed
      @users_batch_size = 50
      @num_fetchers = 8
      @num_parsers = 4
    end

    def call
      total_articles_count = 0

      users.in_batches(of: users_batch_size) do |batch_of_users|
        feeds_per_user_id = fetch_feeds(batch_of_users)

        feedjira_objects = parse_feeds(feeds_per_user_id)

        # NOTE: doing this sequentially to avoid locking problems with the DB
        # and unnecessary conflicts
        articles = feedjira_objects.flat_map do |user_id, feed|
          # TODO: replace `feed` with `feed.url` as `Feeds::AssembleArticleMarkdown`
          # only actually uses feed.url
          user = batch_of_users.detect { |u| u.id == user_id }

          create_articles_from_user_feed(user, feed)
        end

        total_articles_count += articles.length

        # we use `feed_fetched_at` to mark the last time a particular user's feed has been fetched, parsed and imported
        batch_of_users.update_all(feed_fetched_at: Time.current)
      end

      total_articles_count
    end

    private

    attr_reader :earlier_than, :users_batch_size, :num_fetchers, :num_parsers, :users

    # @return [ActiveRecord::Relation<User>] you'll likely want to set @users from this, but
    #         [@jeremyf]'s choosing not to do that as it makes the implementation just a bit
    #         cleaner.
    def filter_users_from(users_scope:, earlier_than:)
      users_scope = ArticlePolicy.scope_users_authorized_to_action(users_scope: users_scope, action: :create)
      users_scope = users_scope.where(id: Users::Setting.with_feed.select(:user_id))

      return users_scope unless earlier_than

      # Filtering users whose feed hasn't been processed in the last `earlier_than` time span.
      # New users + any user whose feed was processed earlier than the given time
      users_scope.where(feed_fetched_at: nil).or(users_scope.where(feed_fetched_at: ..earlier_than))
    end

    # TODO: put this in separate service object
    def fetch_feeds(batch_of_users)
      data = batch_of_users.joins(:setting).pluck(:id, "users_settings.feed_url")

      result = Parallel.map(data, in_threads: num_fetchers) do |user_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        response = HTTParty.get(cleaned_url,
                                timeout: 10,
                                headers: { "User-Agent" => "Forem Feeds Importer" })

        [user_id, response.body]
      rescue StandardError => e
        # TODO: add better exception handling
        # For example, we should stop pulling feeds that return 404 and disable them?

        report_error(
          e,
          feeds_import_info: {
            user_id: user_id,
            url: url,
            error: "Feeds::Import::FetchFeedError"
          },
        )

        next
      end

      result.compact.to_h
    end

    # TODO: put this in separate service object
    def parse_feeds(feeds_per_user_id)
      result = Parallel.map(feeds_per_user_id, in_threads: num_parsers) do |user_id, feed_xml|
        parsed_feed = Feedjira.parse(feed_xml)

        [user_id, parsed_feed]
      rescue StandardError => e
        # TODO: add better exception handling (eg. rescuing Feedjira::NoParserAvailable separately)
        report_error(
          e,
          feeds_import_info: {
            user_id: user_id,
            error: "Feeds::Import::ParseFeedError"
          },
        )

        next
      end

      result.compact.to_h
    end

    # TODO: currently this is exactly as it was in the RssReader, but we might find
    # avenues for optimization, like:
    # 1. why are we sending N exists query to the DB, one per each item, can we fetch them all?
    # 2. should we queue a batch of workers to create articles, but then, following issues ensue:
    # => synchronization on write (table/row locking)
    # => what happens if 2 jobs are in the queue for the same article?
    # => what happens if they stay in the queue for long and the next iteration of the feeds importer starts?
    def create_articles_from_user_feed(user, feed)
      articles = []

      feed.entries.reverse_each do |item|
        next if Feeds::CheckItemMediumReply.call(item) || Feeds::CheckItemPreviouslyImported.call(item, user)

        feed_source_url = item.url.strip.split("?source=")[0]
        article = Article.create!(
          feed_source_url: feed_source_url,
          user_id: user.id,
          published_from_feed: true,
          show_comments: true,
          body_markdown: Feeds::AssembleArticleMarkdown.call(item, user, feed, feed_source_url),
          organization_id: nil,
        )

        subscribe_author_to_comments(user, article)
        articles.append(article)
      rescue StandardError => e
        # TODO: add better exception handling
        report_error(
          e,
          feeds_import_info: {
            username: user.username,
            feed_url: user.setting&.feed_url,
            item_count: item_count_error(feed),
            error: "Feeds::Import::CreateArticleError:#{item.url}"
          },
        )

        next
      end

      if articles.length.positive?
        Slack::WorkflowWebhookWorker.perform_async("Imported #{articles.length} articles for #{user.username}")
      end

      articles
    end

    def report_error(error, metadata)
      Rails.logger.error(
        "feeds::import::error::#{error.class}::#{metadata.merge(error_message: error.message)}",
      )
    end

    def item_count_error(feed)
      return "NIL FEED, INVALID URL" unless feed

      feed.entries ? feed.entries.length : "no count"
    end

    def subscribe_author_to_comments(user, article)
      NotificationSubscription.create!(
        user: user,
        notifiable_id: article.id,
        notifiable_type: "Article",
        config: "all_comments",
      )
    end
  end
end
