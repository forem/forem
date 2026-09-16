module Feeds
  class ImportFromXml < ApplicationService
    MAX_XML_SIZE = 500.kilobytes

    def self.call(xml_content:, user:)
      new(xml_content: xml_content, user: user).perform
    end

    def initialize(xml_content:, user:)
      @xml_content = xml_content
      @user = user
    end

    def perform
      return { error: I18n.t("feeds.xml_imports.blank") } if xml_content.blank?
      return { error: I18n.t("feeds.xml_imports.too_large") } if xml_content.bytesize > MAX_XML_SIZE

      feed = Feedjira.parse(xml_content)
      imported = 0

      feed.entries.reverse_each do |item|
        next if Feeds::CheckItemPreviouslyImported.call(item, user)

        normalized_url = item.url.to_s.strip.split("?source=")[0]

        markdown = Feeds::AssembleArticleMarkdown.call(item, user, feed, normalized_url)
        Article.create!(
          user: user,
          feed_source_url: normalized_url,
          published_from_feed: true,
          body_markdown: markdown,
        )
        imported += 1
      rescue StandardError => e
        Rails.logger.error(
          "Feeds::ImportFromXml item error: #{e.class} - #{e.message} " \
          "for item: #{item.url}. Backtrace: #{e.backtrace&.first(5)&.join(' | ')}"
        )
      end

      { imported: imported }
    rescue Feedjira::NoParserAvailable
      { error: I18n.t("feeds.xml_imports.invalid_xml") }
    end

    private

    attr_reader :xml_content, :user
  end
end
