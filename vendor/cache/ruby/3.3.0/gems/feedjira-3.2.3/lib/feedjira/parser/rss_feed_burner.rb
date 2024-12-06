# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with RSS feeds.
    class RSSFeedBurner
      include SAXMachine
      include FeedUtilities
      element :title
      element :description
      element :link, as: :url
      element :lastBuildDate, as: :last_built
      elements :"atom10:link", as: :hubs, value: :href, with: { rel: "hub" }
      elements :item, as: :entries, class: RSSFeedBurnerEntry

      attr_accessor :feed_url

      def self.able_to_parse?(xml) # :nodoc:
        (/<rss|<rdf/ =~ xml) && xml.include?("feedburner")
      end
    end
  end
end
