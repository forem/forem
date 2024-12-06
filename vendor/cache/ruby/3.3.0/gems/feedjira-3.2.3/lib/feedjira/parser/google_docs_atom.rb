# frozen_string_literal: true

require File.expand_path("./atom", File.dirname(__FILE__))
module Feedjira
  module Parser
    class GoogleDocsAtom
      include SAXMachine
      include FeedUtilities
      element :title
      element :subtitle, as: :description
      element :link, as: :url, value: :href, with: { type: "text/html" }
      element :link, as: :feed_url, value: :href, with: { type: "application/atom+xml" }
      elements :link, as: :links, value: :href
      elements :entry, as: :entries, class: GoogleDocsAtomEntry

      def url
        @url ||= links.first
      end

      def self.able_to_parse?(xml) # :nodoc:
        %r{<id>https?://docs\.google\.com/.*</id>} =~ xml
      end

      def feed_url
        @feed_url ||= links.first
      end
    end
  end
end
