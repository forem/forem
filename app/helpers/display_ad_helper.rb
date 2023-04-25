module DisplayAdHelper
  def display_ads_placement_area_options_array
    DisplayAd::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(DisplayAd::ALLOWED_PLACEMENT_AREAS)
  end

  def audience_segments_for_display_ads
    AudienceSegment.human_readable_segments
  end
end
