module DataUpdateScripts
  class ReprocessMarkdownFeedImports
    FETCH_TIMEOUT = 20
    FEED_USER_AGENT = "Forem/1.0 (+https://forem.com; RSS Feed Fetcher)".freeze

    def run
      log("Starting reprocessing of markdown feed imports...")

      draft_feed_articles = Article.where(published_from_feed: true, published: false)
      total = draft_feed_articles.count
      log("Found #{total} draft feed-imported articles")

      return if total.zero?

      # Group articles by their feed source to batch re-fetches
      articles_by_feed = group_articles_by_feed_source(draft_feed_articles)
      log("Grouped into #{articles_by_feed.size} unique feeds")

      fixed = 0
      skipped = 0
      errored = 0

      articles_by_feed.each do |feed_url, articles|
        feed = fetch_and_parse_feed(feed_url)
        unless feed
          log("  Could not fetch/parse feed: #{feed_url}, skipping #{articles.size} articles")
          skipped += articles.size
          next
        end

        entries_by_url = index_entries_by_url(feed)

        articles.each do |article|
          entry = entries_by_url[article.feed_source_url]
          unless entry
            skipped += 1
            next
          end

          content = entry.content || entry.summary
          if content.blank? || html_content?(content)
            skipped += 1
            next
          end

          # This article had markdown content that was mangled by the HTML pipeline.
          # Re-assemble the body markdown using the fixed code.
          source = find_feed_source(article, feed_url)
          new_markdown = Feeds::AssembleArticleMarkdown.call(
            entry, article.user, feed, article.feed_source_url, feed_source: source
          )
          article.update!(body_markdown: new_markdown)
          fixed += 1
        rescue StandardError => e
          log("  Error reprocessing article #{article.id}: #{e.message}")
          errored += 1
        end
      end

      log("Completed: #{fixed} fixed, #{skipped} skipped, #{errored} errors (of #{total} total)")
    end

    private

    def group_articles_by_feed_source(articles)
      result = {}

      articles.find_each do |article|
        # Try to find the feed URL via Feeds::Source
        source = Feeds::Source.joins(import_logs: :import_items)
          .where(feed_import_items: { article_id: article.id })
          .first

        # Fall back to deriving the feed URL from the article's feed_source_url domain
        feed_url = source&.feed_url
        unless feed_url
          # Try matching by user's feed sources
          source = Feeds::Source.where(user_id: article.user_id).first
          feed_url = source&.feed_url
        end

        next unless feed_url

        result[feed_url] ||= []
        result[feed_url] << article
      end

      result
    end

    def fetch_and_parse_feed(url)
      response = HTTParty.get(url,
                              timeout: FETCH_TIMEOUT,
                              headers: { "User-Agent" => FEED_USER_AGENT })
      Feedjira.parse(response.body)
    rescue StandardError => e
      log("  Fetch/parse error for #{url}: #{e.class} - #{e.message}")
      nil
    end

    def index_entries_by_url(feed)
      feed.entries.index_by { |e| e.url.to_s.strip.split("?source=")[0] }
    end

    def find_feed_source(article, feed_url)
      Feeds::Source.find_by(user_id: article.user_id, feed_url: feed_url)
    end

    def html_content?(content)
      block_tag_count = content.scan(/<\s*(p|div|h[1-6]|ul|ol|li|blockquote|pre|table|section|figure)[\s>]/i).size
      return false if block_tag_count.zero?

      paragraph_breaks = content.scan(/\n\s*\n/).size
      block_tag_count > paragraph_breaks
    end

    def log(message)
      Rails.logger.info("[ReprocessMarkdownFeedImports] #{message}")
    end
  end
end
