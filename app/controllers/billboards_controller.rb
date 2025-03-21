class BillboardsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show], unless: -> { current_user }
  include BillboardHelper
  CACHE_EXPIRY_FOR_BILLBOARDS = 3.minutes.to_i.freeze
  RANDOM_USER_TAG_RANGE_MIN = 5
  RANDOM_USER_TAG_RANGE_MAX = 32

  def show
    skip_authorization

    if ApplicationConfig["DISABLE_BILLBOARDS"] == "yes" # Turned on if needed
      render plain: ""
      return
    end

    unless session_current_user_id
      set_cache_control_headers(CACHE_EXPIRY_FOR_BILLBOARDS)
      if FeatureFlag.enabled?(Geolocation::FEATURE_FLAG)
        add_vary_header("X-Cacheable-Client-Geo")
      end
    end

    if placement_area
      if return_test_billboard?
        @billboard = Billboard.find_by(id: params[:bb_test_id])
        render layout: false
        return
      end

      if params[:username].present? && params[:slug].present?
        @article = Article.find_by(slug: params[:slug])
      end

      @billboard = Billboard.for_display(
        area: placement_area,
        user_signed_in: user_signed_in?,
        user_id: current_user&.id,
        article: @article ? ArticleDecorator.new(@article) : nil,
        page_id: params[:page_id],
        user_tags: user_tags,
        cookies_allowed: cookies_allowed?,
        location: client_geolocation,
        user_agent: request.user_agent,
        role_names: current_user&.cached_role_names,
      )

      if @billboard && !session_current_user_id
        set_surrogate_key_header @billboard.record_key
      end
    end

    render layout: false
  end

  private

  def placement_area
    params[:placement_area]
  end

  def user_tags
    return unless feed_targeted_tag_placement?(placement_area)

    # We limit the tags considered for this location to a max of 32
    # cached_followed_tag_names is ordered by points
    # So we randomaly take from the top of the list in order to return
    # higher-point tags more often for that user.
    current_user&.cached_followed_tag_names&.first(rand(RANDOM_USER_TAG_RANGE_MIN..RANDOM_USER_TAG_RANGE_MAX))
  end

  def return_test_billboard?
    param_present = params[:bb_test_placement_area] == placement_area && params[:bb_test_id].present?
    present_and_admin = param_present && current_user&.any_admin?
    present_and_live = param_present && Billboard.approved_and_published.where(id: params[:bb_test_id]).any?
    present_and_admin || present_and_live
  end

  def cookies_allowed?
    params[:cookies_allowed] == "true"
  end
end
