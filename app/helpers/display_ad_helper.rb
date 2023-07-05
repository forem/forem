module DisplayAdHelper
  def display_ads_placement_area_options_array
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
end
