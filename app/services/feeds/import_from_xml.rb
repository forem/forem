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

        markdown = Feeds::AssembleArticleMarkdown.call(item, user, feed, item.url)
        Article.create!(
          user: user,
          feed_source_url: item.url,
          published_from_feed: true,
          body_markdown: markdown,
        )
        imported += 1
      rescue StandardError => e
        Rails.logger.error("Feeds::ImportFromXml item error: #{e.message}")
      end

      { imported: imported }
    rescue Feedjira::NoParserAvailable
      { error: I18n.t("feeds.xml_imports.invalid_xml") }
    end

    private

    attr_reader :xml_content, :user
  end
end
