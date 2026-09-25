module Feeds
  class ImportFromXml < ApplicationService
    MAX_XML_SIZE = 500.kilobytes
    MAX_ENTRIES = 25

    def self.call(xml_content:, user:)
      new(xml_content: xml_content, user: user).perform
    end

    def initialize(xml_content:, user:)
      super()
      @xml_content = xml_content
      @user = user
    end

    def perform
      content_error = validate_xml_content
      return content_error if content_error

      feed = parse_feed
      return { error: I18n.t("feeds.xml_imports.invalid_xml") } if feed.nil?

      feed_error = validate_feed(feed)
      return feed_error if feed_error

      user.with_lock { { imported: import_entries(feed) } }
    end

    private

    attr_reader :xml_content, :user

    def validate_xml_content
      return { error: I18n.t("feeds.xml_imports.blank") } if xml_content.blank?
      return { error: I18n.t("feeds.xml_imports.too_large") } if xml_content.bytesize > MAX_XML_SIZE

      nil
    end

    def parse_feed
      Feedjira.parse(xml_content)
    rescue StandardError => e
      Rails.logger.warn("Feeds::ImportFromXml parse error: #{e.class} - #{e.message}")
      nil
    end

    def validate_feed(feed)
      if feed.blank? || !feed.respond_to?(:entries) || feed.entries.blank?
        return { error: I18n.t("feeds.xml_imports.no_entries") }
      end

      if feed.entries.size > MAX_ENTRIES
        return { error: I18n.t("feeds.xml_imports.too_many_entries", max: MAX_ENTRIES) }
      end

      nil
    end

    def import_entries(feed)
      existing_urls, existing_titles = fetch_existing_article_identifiers(feed.entries)
      imported = 0

      feed.entries.reverse_each do |item|
        imported += 1 if import_entry(item, feed, existing_urls, existing_titles)
      end

      imported
    end

    def import_entry(item, feed, existing_urls, existing_titles)
      return false if skip_entry?(item, existing_urls, existing_titles)

      normalized_url = item.url.to_s.strip.split("?source=")[0]
      cleaned_title = item.title.to_s.strip
      markdown = Feeds::AssembleArticleMarkdown.call(
        item,
        user,
        feed,
        normalized_url,
        remote_fetches: false,
      )

      create_article_with_subscription(normalized_url, markdown)

      existing_urls << normalized_url
      existing_titles << cleaned_title
      true
    rescue StandardError => e
      Rails.logger.error(
        "Feeds::ImportFromXml item error: #{e.class} - #{e.message} " \
        "for item: #{item&.url}. Backtrace: #{e.backtrace&.first(5)&.join(' | ')}",
      )
      false
    end

    def skip_entry?(item, existing_urls, existing_titles)
      return true if item.nil? || item.url.blank? || item.title.blank?
      return true if Feeds::CheckItemMediumReply.call(item)

      normalized_url = item.url.to_s.strip.split("?source=")[0]
      cleaned_title = item.title.to_s.strip

      existing_urls.include?(normalized_url) || existing_titles.include?(cleaned_title)
    end

    def create_article_with_subscription(normalized_url, markdown)
      ActiveRecord::Base.transaction do
        article = Article.create!(
          user: user,
          feed_source_url: normalized_url,
          published_from_feed: true,
          show_comments: true,
          body_markdown: markdown,
        )

        NotificationSubscription.create!(
          user: user,
          notifiable_id: article.id,
          notifiable_type: "Article",
          config: "all_comments",
        )
      end
    end

    def fetch_existing_article_identifiers(entries)
      candidate_urls, candidate_titles = extract_candidates(entries)
      return [Set.new, Set.new] if candidate_urls.empty? && candidate_titles.empty?

      query = existing_articles_query(candidate_urls, candidate_titles)
      build_identifier_sets(query)
    end

    def extract_candidates(entries)
      valid_entries = entries.reject { |item| item.nil? || item.url.blank? || item.title.blank? }
      candidate_urls = valid_entries.map { |item| item.url.to_s.strip.split("?source=")[0] }.compact_blank.uniq
      candidate_titles = valid_entries.map { |item| item.title.to_s.strip }.compact_blank.uniq

      [candidate_urls, candidate_titles]
    end

    def existing_articles_query(candidate_urls, candidate_titles)
      scope = user.articles
      if candidate_urls.any? && candidate_titles.any?
        scope.where(feed_source_url: candidate_urls).or(scope.where(title: candidate_titles))
      elsif candidate_urls.any?
        scope.where(feed_source_url: candidate_urls)
      else
        scope.where(title: candidate_titles)
      end
    end

    def build_identifier_sets(query)
      existing_urls = Set.new
      existing_titles = Set.new

      query.pluck(:feed_source_url, :title).each do |url, title|
        existing_urls << url if url.present?
        existing_titles << title if title.present?
      end

      [existing_urls, existing_titles]
    end
  end
end
