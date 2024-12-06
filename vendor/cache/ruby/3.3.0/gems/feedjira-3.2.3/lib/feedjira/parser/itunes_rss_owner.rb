# frozen_string_literal: true

module Feedjira
  module Parser
    class ITunesRSSOwner
      include SAXMachine
      include FeedUtilities

      element :"itunes:name", as: :name
      element :"itunes:email", as: :email
    end
  end
end
