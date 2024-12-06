# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with Feedburner Atom feeds.
    class AtomGoogleAlerts
      include SAXMachine
      include FeedUtilities

      element :title
      element :subtitle, as: :description
      element :link, as: :feed_url, value: :href, with: { rel: "self" }
      element :link, as: :url, value: :href, with: { rel: "self" }
      elements :link, as: :links, value: :href
      elements :entry, as: :entries, class: AtomGoogleAlertsEntry

      def self.able_to_parse?(xml)
        Atom.able_to_parse?(xml) && (%r{<id>tag:google\.com,2005:[^<]+/com\.google/alerts/} === xml) # rubocop:disable Style/CaseEquality
      end

      def self.preprocess(xml)
        Preprocessor.new(xml).to_xml
      end
    end
  end
end
