# frozen_string_literal: true

module Feedjira
  module Parser
    class AtomYoutubeEntry
      include SAXMachine
      include FeedEntryUtilities
      include AtomEntryUtilities

      sax_config.top_level_elements["link"].clear
      sax_config.collection_elements["link"].clear

      element :link, as: :url, value: :href, with: { rel: "alternate" }

      element :"media:description", as: :content
      element :"yt:videoId", as: :youtube_video_id
      element :"yt:channelId", as: :youtube_channel_id
      element :"media:title", as: :media_title
      element :"media:content", as: :media_url, value: :url
      element :"media:content", as: :media_type, value: :type
      element :"media:content", as: :media_width, value: :width
      element :"media:content", as: :media_height, value: :height
      element :"media:thumbnail", as: :media_thumbnail_url, value: :url
      element :"media:thumbnail", as: :media_thumbnail_width, value: :width
      element :"media:thumbnail", as: :media_thumbnail_height, value: :height
      element :"media:starRating", as: :media_star_count, value: :count
      element :"media:starRating", as: :media_star_average, value: :average
      element :"media:statistics", as: :media_views, value: :views
    end
  end
end
