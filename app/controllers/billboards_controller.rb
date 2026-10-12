class BillboardsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show], unless: -> { current_user }
  after_action :never_share_signed_in_responses_setting_cookies, only: %i[show]
  include BillboardHelper
  RANDOM_USER_TAG_RANGE_MIN = 5
  RANDOM_USER_TAG_RANGE_MAX = 32

  def show
    skip_authorization

    if ApplicationConfig["DISABLE_BILLBOARDS"] == "yes" # Turned on if needed
      set_cache_control_headers(180)
      render plain: ""
      return
    end

    if edge_cached_response?
      cache_expiry = BillboardPlacementAreaConfig.cache_expiry_seconds_for(placement_area)
      set_cache_control_headers(cache_expiry)
      add_vary_header("X-Cacheable-Client-Geo") if vary_on_client_geo?
    end

    @viewer_country = viewer_country
    @anonymous_tracking_allowed = anonymous_tracking_allowed?

    if placement_area
      if return_test_billboard?
        @billboard = Billboard.find_by(id: params[:bb_test_id])
        render layout: false
        return
      end

      @billboard = fully_cached_request? ? fully_cached_billboard : contextual_billboard

      if @billboard && edge_cached_response?
        set_surrogate_key_header @billboard.record_key
      end
    end

    render layout: false
  end

  private

  def placement_area
    params[:placement_area]
  end

  def contextual_billboard
    if params[:username].present? && params[:slug].present?
      path = "/#{params[:username].downcase}/#{params[:slug].downcase}"
      @article = Article.find_by(path: path) || Article.find_by(slug: params[:slug])
    end

    Billboard.for_display(
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
  end

  # Nothing about the individual visitor is used here, not even current_user (which is off
  # limits once edge-cache headers are set), so the response can be shared by everyone in a
  # location. Signed-in state is still used: Fastly keeps signed-in and signed-out copies of
  # every response apart (X-Loggedin), so it costs no extra cache splitting.
  def fully_cached_billboard
    Billboard.for_display(
      area: placement_area,
      user_signed_in: session_current_user_id.present?,
      cookies_allowed: cookies_allowed?,
      location: billboard_geolocation,
      fully_cached: true,
    )
  end

  # Placement areas configured as fully cached get one edge-cached response per location,
  # shared by every article and page and by signed-in visitors too. Pages request these areas
  # through a URL without article or page context (see BillboardHelper#billboard_async_path).
  # Requests that still carry context, such as articles whose authors opt out of adjacent
  # sponsors, test billboard previews, or pages cached before the area was switched, are
  # served exactly as before.
  def fully_cached_request?
    return @fully_cached_request if defined?(@fully_cached_request)

    @fully_cached_request = placement_area.present? &&
      params[:username].blank? && params[:slug].blank? && params[:page_id].blank? &&
      params[:bb_test_placement_area].blank? &&
      BillboardPlacementAreaConfig.fully_cached_for(placement_area)
  end

  # A fully cached response is shared by every signed-in visitor in a location, so it must never
  # set cookies. Devise does exactly that when it logs someone back in from their remember-me
  # cookie (refreshing it), and everyone sharing a cached copy would receive that visitor's cookie.
  def never_share_signed_in_responses_setting_cookies
    return unless fully_cached_request? && session_current_user_id

    pending_cookies = Rack::Response.new
    cookies.write(pending_cookies)
    unset_cache_control_headers if pending_cookies.headers["Set-Cookie"].present?
  end

  # Whether this response is cached at the edge and shared with other visitors.
  def edge_cached_response?
    fully_cached_request? || !session_current_user_id
  end

  # Shared responses must use the same location as every other visitor sharing them, which is
  # the cacheable one they vary on. Only uncached, signed-in responses use the precise location.
  def billboard_geolocation
    fully_cached_request? ? request.headers["X-Cacheable-Client-Geo"] : client_geolocation
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

  # Signed-out and fully cached billboard responses are cached at the edge. Anything in them that
  # depends on where the visitor is (location-targeted billboards, the viewer's country, whether
  # anonymous tracking is allowed) is only safe to render when that cache varies on the geo header
  # it was derived from. Otherwise one visitor's location would be served to everyone sharing it.
  def vary_on_client_geo?
    return @vary_on_client_geo if defined?(@vary_on_client_geo)

    @vary_on_client_geo = FeatureFlag.enabled?(Geolocation::FEATURE_FLAG) ||
      Settings::General.geos_with_allowed_anonymous_tracking.any?
  end

  # The viewer's country (ISO 3166-1 alpha-2) as geolocated by Fastly, sent with the billboard
  # as data-viewer-country so client-side code can tailor content to where the reader is.
  #
  # Signed-out visitors are read from X-Cacheable-Client-Geo, which Fastly leaves blank for
  # countries outside its active_geofencing_regions dictionary, so it is nil for them.
  def viewer_country
    return if edge_cached_response? && !vary_on_client_geo?

    country = billboard_geolocation.to_s.split(Geolocation::ISO3166_SEPARATOR).first
    country if country&.match?(/\A[A-Z]{2}\z/)
  end

  # Whether this signed-out visitor's region allows keeping an anonymous identifier, and a
  # tally of the tags they read, in their browser. Sent with the billboard as
  # data-anonymous-tracking-allowed and acted on by app/javascript/utilities/anonymousVisitor.js.
  #
  # This is for serving better content to anonymous readers. Each Forem's admins choose the
  # regions (Settings::General.geos_with_allowed_anonymous_tracking) and are responsible for it
  # being lawful there. Regions that require consent for device storage (e.g. the EU and UK) need
  # cookie banner consent first, and using this data for ads must be allowed for advertising in
  # that region and/or be compatible with the cookie banner. See the setting for details.
  def anonymous_tracking_allowed?
    return false if session_current_user_id

    Geolocation.code_covered_by?(billboard_geolocation, Settings::General.geos_with_allowed_anonymous_tracking)
  end
end
