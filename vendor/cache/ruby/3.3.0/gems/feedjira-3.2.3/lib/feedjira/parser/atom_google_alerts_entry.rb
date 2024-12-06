# frozen_string_literal: true

require "uri"

module Feedjira
  module Parser
    # Parser for dealing with Feedburner Atom feed entries.
    class AtomGoogleAlertsEntry
      include SAXMachine
      include FeedEntryUtilities
      include AtomEntryUtilities

      def url
        url = super
        return unless url&.start_with?("https://www.google.com/url?")

        uri = URI(url)
        cons = URI.decode_www_form(uri.query).assoc("url")
        cons && cons[1]
      end
    end
  end
end
