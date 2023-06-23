module BillboardHelper
  def billboards_placement_area_options_array
    Billboard::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(Billboard::ALLOWED_PLACEMENT_AREAS)
  end

  def audience_segments_for_billboards
    AudienceSegment.human_readable_segments
  end
end
