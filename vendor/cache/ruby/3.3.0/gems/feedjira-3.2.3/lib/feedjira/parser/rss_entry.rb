# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with RDF feed entries.
    class RSSEntry
      include SAXMachine
      include FeedEntryUtilities
      include RSSEntryUtilities
    end
  end
end
