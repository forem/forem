# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with RDF feed entries.
    class RSSFeedBurnerEntry
      include SAXMachine
      include FeedEntryUtilities
      include RSSEntryUtilities

      element :"feedburner:origLink", as: :orig_link
      private :orig_link

      def url
        orig_link || super
      end
    end
  end
end
