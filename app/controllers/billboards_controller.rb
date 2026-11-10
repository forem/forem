class BillboardsController < ApplicationController
  skip_before_action :remember_cookie_sync,
                     :forward_to_app_config_domain,
                     :redirect_custom_domain_non_profile_pages,
                     :set_request_signed_in_context,
                     only: %i[show]
  before_action :set_cache_control_headers, only: %i[show], unless: -> { viewer_signed_in? }
  after_action :never_share_signed_in_responses_setting_cookies, only: %i[show]
  include BillboardHelper
  RANDOM_USER_TAG_RANGE_MIN = 5
  RANDOM_USER_TAG_RANGE_MAX = 32
  # Only the columns needed to validate the session salt and compute `cached_followed_tag_names`
  # and `cached_role_names` on contextual requests, avoiding `SELECT "users".*` (97 columns).
  VIEWER_COLUMNS = %i[id encrypted_password following_tags_count last_followed_at].freeze
  # The only article attributes Billboard.for_display reads. Loading just these skips the
  # article's large columns (processed_html, body_markdown, embeddings) on every request.
  ARTICLE_TARGETING_COLUMNS = %i[id user_id co_author_ids organization_id cached_tag_list].freeze
  # Answers ArticleDecorator#permit_adjacent_sponsors? in the article lookup itself, saving a
  # separate users_settings query per request. permit_adjacent_sponsors is nullable; nil opts out.
  # Wrap in `.as(...)` (an Arel::Nodes::As node) with `retryable: true` so Relation#arel_column
  # preserves retryability instead of stringifying the SqlLiteral and setting allow_retry: false.
  ADJACENT_SPONSORS_PERMITTED = Arel.sql(<<~SQL.squish, retryable: true).as("adjacent_sponsors_permitted")
    NOT EXISTS (SELECT 1 FROM users_settings
      WHERE users_settings.user_id = ANY(array_prepend(articles.user_id, articles.co_author_ids))
      AND (users_settings.permit_adjacent_sponsors = FALSE OR users_settings.permit_adjacent_sponsors IS NULL))
  SQL

  def show
    skip_authorization
    RequestStore.store[:user_signed_in] = viewer_signed_in?
    request.session_options[:skip] = true unless remembered_user_restored?

    if ApplicationConfig["DISABLE_BILLBOARDS"] == "yes" # Turned on if needed
      set_cache_control_headers(180)
      render plain: ""
      return
    end

    if edge_cached_response?
      cache_expiry = BillboardPlacementAreaConfig.cache_expiry_seconds_for(placement_area)
      set_cache_control_headers(cache_expiry)
      request.session_options[:skip] = true unless remembered_user_restored? || flash_pending?
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

      set_surrogate_key_header(*billboard_surrogate_keys) if edge_cached_response?
    end

    render layout: false
  end

  private

  def placement_area
    params[:placement_area]
  end

  # Override Devise's `user_signed_in?` helper so `_billboard_header.html.erb` and
  # `verify_private_forem` never force Warden to run `SELECT "users".*`.
  def user_signed_in?
    viewer_signed_in?
  end

  def viewer_signed_in?
    return @viewer_signed_in if defined?(@viewer_signed_in)

    @viewer_signed_in = if fully_cached_request? && !test_billboard_params_present?
                          loaded_warden_user.present? ||
                            session_or_remembered_user_id(validate_salt: false).present?
                        else
                          viewer_user.present?
                        end
  end

  def viewer_user
    return @viewer_user if defined?(@viewer_user)

    if (warden_user = loaded_warden_user)
      return @viewer_user = warden_user
    end

    uid = session_or_remembered_user_id(validate_salt: false)
    return @viewer_user = loaded_warden_user if @remembered_user_restored
    return @viewer_user = nil unless uid

    candidate = User.select(*VIEWER_COLUMNS).find_by(id: uid)
    @viewer_user = valid_session_viewer?(candidate) ? candidate : nil
  end

  def loaded_warden_user
    request.env["warden"]&.instance_variable_get(:@users)&.[](:user)
  end

  def test_billboard_params_present?
    params[:bb_test_placement_area] == placement_area && params[:bb_test_id].present?
  end

  # Selects a billboard for the requested placement area using article, page, and viewer context.
  def contextual_billboard
    if BillboardPlacementAreaConfig.delivery_rate_for(placement_area: placement_area,
                                                      user_signed_in: viewer_signed_in?) <= 0
      return
    end

    if params[:username].present? && params[:slug].present?
      path = "/#{params[:username].downcase}/#{params[:slug].downcase}"
      articles = Article.select(*ARTICLE_TARGETING_COLUMNS, ADJACENT_SPONSORS_PERMITTED)
      @article = articles.find_by(path: path) || articles.find_by(slug: params[:slug])
    end

    viewer = viewer_user
    renderable_billboards.for_display(
      area: placement_area,
      user_signed_in: viewer_signed_in?,
      user_id: viewer&.id,
      article: @article ? ArticleDecorator.new(@article) : nil,
      page_id: params[:page_id],
      user_tags: user_tags,
      cookies_allowed: cookies_allowed?,
      location: client_geolocation,
      user_agent: request.user_agent,
      role_names: viewer&.cached_role_names,
    )
  end

  # Nothing about the individual visitor is used here, not even current_user (which is off
  # limits once edge-cache headers are set), so the response can be shared by everyone in a
  # location. Signed-in state is still used: Fastly keeps signed-in and signed-out copies of
  # every response apart (X-Loggedin), so it costs no extra cache splitting.
  def fully_cached_billboard
    renderable_billboards.for_display(
      area: placement_area,
      user_signed_in: viewer_signed_in?,
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
  #
  # Article and page areas requested without their context are served the same way even once
  # the area is no longer fully cached: those requests come from pages rendered while it was,
  # which can stay cached for a while, and have no article or page to target billboards at.
  def fully_cached_request?
    return @fully_cached_request if defined?(@fully_cached_request)

    @fully_cached_request = placement_area.present? &&
      params[:username].blank? && params[:slug].blank? && params[:page_id].blank? &&
      params[:bb_test_placement_area].blank? &&
      (BillboardPlacementAreaConfig.fully_cached_for(placement_area) ||
        Billboard::CONTEXTUAL_PLACEMENTS.include?(placement_area))
  end

  def billboard_surrogate_keys
    [
      @billboard&.record_key,
      BillboardPlacementAreaConfig::RESPONSES_SURROGATE_KEY,
      BillboardPlacementAreaConfig.responses_surrogate_key_for(placement_area),
    ].compact
  end

  # Delivery renders processed HTML; Markdown source is only needed when editing.
  def renderable_billboards
    Billboard.select(Billboard.column_names - %w[body_markdown minimized_body_markdown])
  end

  # A fully cached response is shared by every signed-in visitor in a location, so it must never
  # set cookies. Devise does exactly that when it logs someone back in from their remember-me
  # cookie (refreshing it), and everyone sharing a cached copy would receive that visitor's cookie.
  def never_share_signed_in_responses_setting_cookies
    return unless fully_cached_request? && viewer_signed_in?

    pending_cookies = Rack::Response.new
    cookies.write(pending_cookies)
    unset_cache_control_headers if pending_cookies.headers["Set-Cookie"].present?
  end

  # Whether this response is cached at the edge and shared with other visitors.
  def edge_cached_response?
    fully_cached_request? || !viewer_signed_in?
  end

  # Shared responses must use the same location as every other visitor sharing them, which is
  # the cacheable one they vary on. Only uncached, signed-in responses use the precise location.
  def billboard_geolocation
    fully_cached_request? ? request.headers["X-Cacheable-Client-Geo"] : client_geolocation
  end

  def client_geolocation
    if viewer_signed_in?
      request.headers["X-Client-Geo"]
    else
      request.headers["X-Cacheable-Client-Geo"]
    end
  end

  def user_tags
    return unless feed_targeted_tag_placement?(placement_area)

    # We limit the tags considered for this location to a max of 32
    # cached_followed_tag_names is ordered by points
    # So we randomaly take from the top of the list in order to return
    # higher-point tags more often for that user.
    viewer_user&.cached_followed_tag_names&.first(rand(RANDOM_USER_TAG_RANGE_MIN..RANDOM_USER_TAG_RANGE_MAX))
  end

  def return_test_billboard?
    param_present = test_billboard_params_present?
    present_and_admin = param_present && viewer_user&.any_admin?
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

    geo = billboard_geolocation
    native = ForemNative.extract_viewer_country(geo)
    return if native == false
    return native if native

    country = geo.to_s.split(Geolocation::ISO3166_SEPARATOR).first
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
    return false if viewer_signed_in?

    Geolocation.code_covered_by?(billboard_geolocation, Settings::General.geos_with_allowed_anonymous_tracking)
  end
end
