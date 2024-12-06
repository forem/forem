# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with RSS feeds.
    # Source: https://cyber.harvard.edu/rss/rss.html
    class RSS
      include SAXMachine
      include FeedUtilities
      element :description
      element :image, class: RSSImage
      element :language
      element :lastBuildDate, as: :last_built
      element :link, as: :url
      element :"a10:link", as: :url, value: :href
      element :rss, as: :version, value: :version
      element :title
      element :ttl
      elements :"atom:link", as: :hubs, value: :href, with: { rel: "hub" }
      elements :item, as: :entries, class: RSSEntry

      attr_accessor :feed_url

      def self.able_to_parse?(xml)
        (/<rss|<rdf/ =~ xml) && !xml.include?("feedburner")
      end
    end
  end
end
