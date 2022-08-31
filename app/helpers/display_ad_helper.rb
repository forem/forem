module DisplayAdHelper
  def display_ads_placement_area_options_array
    DisplayAd::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(DisplayAd::ALLOWED_PLACEMENT_AREAS)
  end

  def display_ad_visible_to_current_user(placement_area)
    @display_ad_visible_to_current_user ||= if user_can_see_sponsors? && author_allows_sponsors?
                                              DisplayAd.for_display(placement_area)
                                            end
  end

  private

  def user_can_see_sponsors?
    @user_can_see_sponsors ||= current_user&.display_sponsors
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def author_allows_sponsors?
    @author_allows_sponsors ||= @article&.user&.permit_adjacent_sponsors
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
