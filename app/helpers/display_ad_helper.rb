module DisplayAdHelper
  def display_ads_placement_area_options_array
    DisplayAd::ALLOWED_PLACEMENT_AREAS.map
      .with_index { |area, index| [DisplayAd::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE[index], area] }
  end
end
