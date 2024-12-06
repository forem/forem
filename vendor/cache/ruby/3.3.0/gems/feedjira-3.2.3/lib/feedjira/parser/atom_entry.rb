# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with Atom feed entries.
    class AtomEntry
      include SAXMachine
      include FeedEntryUtilities
      include AtomEntryUtilities

      element :"media:thumbnail", as: :image, value: :url
      element :"media:content", as: :image, value: :url
    end
  end
end
