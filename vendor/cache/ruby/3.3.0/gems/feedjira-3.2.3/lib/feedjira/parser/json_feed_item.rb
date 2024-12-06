# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with JSON Feed items.
    class JSONFeedItem
      include FeedEntryUtilities

      attr_reader :json, :entry_id, :url, :external_url, :title, :content, :summary,
                  :published, :updated, :image, :banner_image, :author, :categories

      def initialize(json)
        @json = json
        @entry_id = json.fetch("id")
        @url = json.fetch("url")
        @external_url = json.fetch("external_url", nil)
        @title = json.fetch("title", nil)
        @content = parse_content(json.fetch("content_html", nil), json.fetch("content_text", nil))
        @summary = json.fetch("summary", nil)
        @image = json.fetch("image", nil)
        @banner_image = json.fetch("banner_image", nil)
        @published = parse_published(json.fetch("date_published", nil))
        @updated = parse_updated(json.fetch("date_modified", nil))
        @author = author_name(json.fetch("author", nil))
        @categories = json.fetch("tags", [])
      end

      private

      def parse_published(date_published)
        return nil unless date_published

        Time.parse_safely(date_published)
      end

      def parse_updated(date_modified)
        return nil unless date_modified

        Time.parse_safely(date_modified)
      end

      # Convenience method to return the included content type.
      # Prefer content_html unless it isn't included.
      def parse_content(content_html, content_text)
        return content_html unless content_html.nil?

        content_text
      end

      def author_name(author_obj)
        return nil if author_obj.nil?

        author_obj["name"]
      end
    end
  end
end
