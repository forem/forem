module DisplayAdHelper
  def display_ads_placement_area_options_array
    DisplayAd::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(DisplayAd::ALLOWED_PLACEMENT_AREAS)
  end

  def audience_segments_for_display_ads
    AudienceSegment.human_readable_segments
  end

  # Determines whether the area provided as a parameter is a targeted tag placement on the feed
  #
  # @return [Boolean] true or false on whether the area is a targeted tag placement on the feed.
  #
  # @note An area of "sidebar_left_2" will return false as it is not part of DisplayAd::HOME_FEED_PLACEMENTS
  # whilst an area of "feed_first" will return false.
  def feed_targeted_tag_placement?(area)
    DisplayAd::HOME_FEED_PLACEMENTS.include?(area)
  end
end
