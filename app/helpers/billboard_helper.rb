module BillboardHelper
  def billboards_placement_area_options_array
    DisplayAd::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(DisplayAd::ALLOWED_PLACEMENT_AREAS)
  end

  def automatic_audience_segments_options_array
    AudienceSegment.not_manual.pluck(:id, :type_of)
      .map { |(id, type)| [AudienceSegment.human_readable_description_for(type), id] }
  end

  def single_audience_segment_option(billboard)
    segment = billboard.audience_segment
    # This should never happen
    raise ArgumentError, "Billboard must have a target audience segment to build option for" if segment.blank?

    [[AudienceSegment.human_readable_description_for(segment.type_of), segment.id]]
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
