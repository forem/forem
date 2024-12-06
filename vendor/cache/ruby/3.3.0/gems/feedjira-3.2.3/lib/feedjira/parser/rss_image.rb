# frozen_string_literal: true

module Feedjira
  module Parser
    # Parser for dealing with RSS images
    class RSSImage
      include SAXMachine

      element :description
      element :height
      element :link
      element :title
      element :url
      element :width
    end
  end
end
