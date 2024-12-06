# frozen_string_literal: true

module Feedjira
  module Parser
    # iTunes is RSS 2.0 + some apple extensions
    # Sources:
    #   * https://cyber.harvard.edu/rss/rss.html
    #   * http://lists.apple.com/archives/syndication-dev/2005/Nov/msg00002.html
    #   * https://help.apple.com/itc/podcasts_connect/
    class ITunesRSS
      include SAXMachine
      include FeedUtilities

      attr_accessor :feed_url

      # RSS 2.0 elements that need including
      element :copyright
      element :description
      element :image, class: RSSImage
      element :language
      element :lastBuildDate, as: :last_built
      element :link, as: :url
      element :managingEditor, as: :managing_editor
      element :rss, as: :version, value: :version
      element :title
      element :ttl

      # If author is not present use managingEditor on the channel
      element :"itunes:author", as: :itunes_author
      element :"itunes:block", as: :itunes_block
      element :"itunes:image", value: :href, as: :itunes_image
      element :"itunes:explicit", as: :itunes_explicit
      element :"itunes:complete", as: :itunes_complete
      element :"itunes:keywords", as: :itunes_keywords
      element :"itunes:type", as: :itunes_type

      # New URL for the podcast feed
      element :"itunes:new_feed_url", as: :itunes_new_feed_url
      element :"itunes:subtitle", as: :itunes_subtitle

      # If summary is not present, use the description tag
      element :"itunes:summary", as: :itunes_summary

      # iTunes RSS feeds can have multiple main categories and multiple
      # sub-categories per category.
      elements :"itunes:category", as: :_itunes_categories,
                                   class: ITunesRSSCategory
      private :_itunes_categories

      def itunes_categories
        _itunes_categories.flat_map do |itunes_category|
          itunes_category.enum_for(:each_subcategory).to_a
        end
      end

      def itunes_category_paths
        _itunes_categories.flat_map do |itunes_category|
          itunes_category.enum_for(:each_path).to_a
        end
      end

      elements :"itunes:owner", as: :itunes_owners, class: ITunesRSSOwner
      elements :item, as: :entries, class: ITunesRSSItem

      def self.able_to_parse?(xml)
        %r{xmlns:itunes\s?=\s?["']http://www\.itunes\.com/dtds/podcast-1\.0\.dtd["']}i =~ xml
      end
    end
  end
end
