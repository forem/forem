# frozen_string_literal: true

module Feedjira
  module Parser
    # iTunes extensions to the standard RSS2.0 item
    # Source: http://www.apple.com/itunes/whatson/podcasts/specs.html
    class ITunesRSSItem
      include SAXMachine
      include FeedEntryUtilities
      include RSSEntryUtilities

      sax_config.top_level_elements["enclosure"].clear

      # If author is not present use author tag on the item
      element :"itunes:author", as: :itunes_author
      element :"itunes:block", as: :itunes_block
      element :"itunes:duration", as: :itunes_duration
      element :"itunes:explicit", as: :itunes_explicit
      element :"itunes:keywords", as: :itunes_keywords
      element :"itunes:subtitle", as: :itunes_subtitle
      element :"itunes:image", value: :href, as: :itunes_image
      element :"itunes:isClosedCaptioned", as: :itunes_closed_captioned
      element :"itunes:order", as: :itunes_order
      element :"itunes:season", as: :itunes_season
      element :"itunes:episode", as: :itunes_episode
      element :"itunes:title", as: :itunes_title
      element :"itunes:episodeType", as: :itunes_episode_type

      # If summary is not present, use the description tag
      element :"itunes:summary", as: :itunes_summary
      element :enclosure, value: :length, as: :enclosure_length
      element :enclosure, value: :type, as: :enclosure_type
      element :enclosure, value: :url, as: :enclosure_url
      elements "psc:chapter", as: :raw_chapters, class: Feedjira::Parser::PodloveChapter

      # Podlove requires clients to re-order by start time in the
      # event the publisher doesn't provide them in that
      # order. SAXMachine doesn't have any sort capability afaik, so
      # we have to sort chapters manually.
      def chapters
        raw_chapters.sort_by(&:start)
      end
    end
  end
end
