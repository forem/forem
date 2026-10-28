module BillboardHelper
  RANDOM_USER_TAG_RANGE_MIN = 5
  RANDOM_USER_TAG_RANGE_MAX = 32

  def billboards_placement_area_options_array
    Billboard::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE.zip(Billboard::ALLOWED_PLACEMENT_AREAS)
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
  # @note An area of "sidebar_left_2" will return false as it is not part of Billboard::HOME_FEED_PLACEMENTS
  # whilst an area of "feed_first" will return false.
  def feed_targeted_tag_placement?(area)
    Billboard::HOME_FEED_PLACEMENTS.include?(area)
  end

  # The URL a page loads a placement area's billboard from.
  #
  # Fully cached placement areas use one URL everywhere, so a single edge-cached response (per
  # location) is shared by every article and page. Articles whose authors opt out of sponsors
  # next to their posts keep their own URL so that choice is still honored.
  #
  # @see BillboardPlacementAreaConfig.fully_cached_for
  def billboard_async_path(placement_area, article: nil, page_id: nil)
    decorated_article = article.is_a?(ArticleDecorator) ? article : article&.decorate
    if BillboardPlacementAreaConfig.fully_cached_for(placement_area.to_s) &&
        (decorated_article.nil? || decorated_article.permit_adjacent_sponsors?)
      billboard_path(placement_area: placement_area)
    elsif article
      article_billboard_path(username: article.username, slug: article.slug, placement_area: placement_area)
    else
      billboard_path(page_id: page_id, placement_area: placement_area)
    end
  end

  # Including here because multiple controllers render this in different contexts
  # When signed in, this is uncached, but it is cached for signed-out contexts
  def get_homepage_sidebar_billboards
    user_tags = current_user&.cached_followed_tag_names
      &.first(rand(RANDOM_USER_TAG_RANGE_MIN..RANDOM_USER_TAG_RANGE_MAX))
    common_params = {
      user_signed_in: user_signed_in?,
      user_id: current_user&.id,
      user_tags: user_tags,
      role_names: current_user&.cached_role_names
    }
    common_params[:location] = client_geolocation if user_signed_in? && FeatureFlag.enabled?(Geolocation::FEATURE_FLAG)
    billboards = []
    billboards << Billboard.for_display(**common_params, area: "sidebar_right")
    billboards << Billboard.for_display(**common_params, area: "sidebar_right_second")
    billboards << Billboard.for_display(**common_params, area: "sidebar_right_third")
  end
end
