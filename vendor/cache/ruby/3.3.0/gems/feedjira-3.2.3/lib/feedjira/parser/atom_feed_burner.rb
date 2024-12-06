# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with Feedburner Atom feeds.
    class AtomFeedBurner
      include SAXMachine
      include FeedUtilities

      element :title
      element :subtitle, as: :description
      element :link, as: :url_text_html, value: :href,
                     with: { type: "text/html" }
      element :link, as: :url_notype, value: :href, with: { type: nil }
      element :link, as: :feed_url_link, value: :href, with: { type: "application/atom+xml" }
      element :"atom10:link", as: :feed_url_atom10_link, value: :href,
                              with: { type: "application/atom+xml" }
      elements :"atom10:link", as: :hubs, value: :href, with: { rel: "hub" }
      elements :entry, as: :entries, class: AtomFeedBurnerEntry

      attr_writer :url, :feed_url

      def self.able_to_parse?(xml)
        (xml.include?("<feed") && xml.include?("Atom") && xml.include?("feedburner") && !(/<rss|<rdf/ =~ xml)) || false
      end

      # Feed url is <link> with type="text/html" if present,
      # <link> with no type attribute otherwise
      def url
        @url || @url_text_html || @url_notype
      end

      # Feed feed_url is <link> with type="application/atom+xml" if present,
      # <atom10:link> with type="application/atom+xml" otherwise
      def feed_url
        @feed_url || @feed_url_link || @feed_url_atom10_link
      end

      def self.preprocess(xml)
        Preprocessor.new(xml).to_xml
      end
    end
  end
end
