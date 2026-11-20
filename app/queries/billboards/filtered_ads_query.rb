module Billboards
  class FilteredAdsQuery
    include BillboardHelper
    def self.call(...)
      new(...).call
    end

    # @param area [String] the site area where the ad is visible
    # @param user_signed_in [Boolean] whether or not the visitor is signed-in
    # @param billboards [Billboard] can be a filtered scope or Arel relationship
    # @param location [Geolocation|String] the visitor's geographic location
    # @param fully_cached [Boolean] whether the response is shared through the edge cache by
    #   everyone in a location (see BillboardPlacementAreaConfig.fully_cached_for)
    def initialize(area:, user_signed_in:, organization_id: nil, article_tags: [], page_id: nil,
                   permit_adjacent_sponsors: true, article_id: nil, billboards: Billboard,
                   user_id: nil, user_tags: nil, location: nil, cookies_allowed: false, user_agent: nil,
                   role_names: nil, subforem_id: nil, fully_cached: false)
      # No organization preload: callers pick a single billboard from the candidates, and only
      # its header partial reads the organization (usually from a cached fragment).
      @filtered_billboards = billboards
      @area = area
      @user_signed_in = user_signed_in
      @user_id = user_signed_in ? user_id : nil
      @page_id = page_id
      @organization_id = organization_id
      @article_tags = article_tags
      @article_id = article_id
      @permit_adjacent_sponsors = permit_adjacent_sponsors
      @user_tags = user_tags
      @user_agent = user_agent
      @location = Geolocation.from_iso3166(location)
      @cookies_allowed = cookies_allowed
      @role_names = role_names
      @subforem_id = subforem_id || RequestStore.store[:subforem_id]
      @fully_cached = fully_cached
    end

    def call
      if (native_relation = build_native_filtered_relation)
        return native_relation
      end

      legacy_call
    end

    private

    def legacy_call
      @filtered_billboards = approved_and_published_ads
      @filtered_billboards = placement_area_ads

      apply_event_broadcast_overrides!

      @filtered_billboards = included_subforem_ads # if @subforem_id.present?
      @filtered_billboards = request_independent_ads if @fully_cached
      @filtered_billboards = browser_context_ads if @user_agent.present?
      @filtered_billboards = page_ads if @page_id.present?
      @filtered_billboards = cookies_allowed_ads unless @cookies_allowed

      apply_legacy_article_and_user_tag_filters!
      apply_legacy_viewer_and_post_filters!

      @filtered_billboards = @filtered_billboards.order(success_rate: :desc)
    end

    def apply_legacy_article_and_user_tag_filters!
      if @article_id.present?
        @filtered_billboards = @article_tags.any? ? tagged_or_untagged_ads(@article_tags) : untagged_ads
        @filtered_billboards = unexcluded_article_ads
      end

      if @user_tags.present? && @user_tags.any?
        @filtered_billboards = tagged_or_untagged_ads(@user_tags)
      elsif @user_tags.blank? && feed_targeted_tag_placement?(@area)
        # We apply the condition feed_targeted_tag_placement? because we only want to filter by
        # untagged ads on the home feed area placements. We do not want to have any side effects happen
        # on the article page or anywhere else.
        @filtered_billboards = untagged_ads
      end
    end

    def apply_legacy_viewer_and_post_filters!
      @filtered_billboards = user_targeting_ads
      @filtered_billboards = role_filtered_ads if @user_signed_in
      @filtered_billboards = authenticated_ads(@user_signed_in ? %w[all logged_in] : %w[all logged_out])
      @filtered_billboards = location_targeted_ads if FeatureFlag.enabled?(Geolocation::FEATURE_FLAG)

      # type_of filter needs to be applied as near to the end as possible
      # as it checks if any type-matching ads exist (this will apply all/any
      # filters applied up to this point, thus near the end is best)
      @filtered_billboards = type_of_ads

      # Exclude paused promotional billboards - apply after type_of_ads to ensure it's not overridden
      @filtered_billboards = exclude_paused_promotional_billboards

      # Apply survey completion filtering if user is signed in
      return unless @user_signed_in && ApplicationConfig["SKIP_SURVEY_COMPLETION_FILTERING"] != "yes"

      @filtered_billboards = survey_completion_filtered_ads
    end

    def build_native_filtered_relation
      params = build_native_where_params
      return unless params

      where_sql = ForemNative.build_filtered_ads_where_sql(params)
      return unless where_sql

      @filtered_billboards = @filtered_billboards.where(Arel.sql(where_sql))
      apply_non_inlineable_org_post_filters! if @organization_id.present?
      @filtered_billboards = @filtered_billboards.order(success_rate: :desc)
    end

    def apply_non_inlineable_org_post_filters!
      @filtered_billboards = type_of_ads
      @filtered_billboards = exclude_paused_promotional_billboards
      return unless @user_signed_in && ApplicationConfig["SKIP_SURVEY_COMPLETION_FILTERING"] != "yes"

      @filtered_billboards = survey_completion_filtered_ads
    end

    def build_native_where_params
      return unless @area.instance_of?(String) && @area.present?
      return unless @user_agent.nil? || @user_agent.instance_of?(String)

      ids = normalize_native_int_fields
      return unless ids

      tag_and_role_lists = normalize_native_string_lists(ids[:article_id])
      return unless tag_and_role_lists

      assemble_native_where_params(ids, tag_and_role_lists)
    end

    def normalize_native_int_fields
      subforem_id = normalize_optional_int(@subforem_id)
      page_id = normalize_optional_int(@page_id)
      article_id = normalize_optional_int(@article_id)
      user_id = normalize_optional_int(@user_id)
      return if [subforem_id, page_id, article_id, user_id].include?(:invalid)

      { subforem_id: subforem_id, page_id: page_id, article_id: article_id, user_id: user_id }
    end

    def normalize_native_string_lists(article_id)
      article_tag_names = article_id ? normalize_tag_names(@article_tags) : []
      has_user_tags = @user_tags.present? && @user_tags.any?
      user_tag_names = has_user_tags ? normalize_tag_names(@user_tags) : []
      role_name_strs = @user_signed_in && @role_names.present? ? normalize_string_list(@role_names) : []
      return unless article_tag_names && user_tag_names && role_name_strs

      {
        article_tag_names: article_tag_names,
        has_user_tags: has_user_tags,
        user_tag_names: user_tag_names,
        role_name_strs: role_name_strs
      }
    end

    def assemble_native_where_params(ids, lists)
      now_utc = Time.current.utc
      loc_enabled = FeatureFlag.enabled?(Geolocation::FEATURE_FLAG)
      include_post_type_of = @organization_id.blank?

      [
        @area,
        now_utc.tv_sec,
        now_utc.usec,
        verified_broadcast_event_ids,
        ids[:subforem_id],
        @fully_cached ? true : false,
        @user_agent,
        ids[:page_id],
        @cookies_allowed ? true : false,
        ids[:article_id],
        lists[:article_tag_names],
        lists[:user_tag_names],
        lists[:has_user_tags],
        ENV["OPTIMIZED_TAGGABLE_QUERY"] == "true",
        @user_signed_in ? true : false,
        ids[:user_id],
        lists[:role_name_strs],
        loc_enabled ? true : false,
        loc_enabled ? @location&.to_sql_query_clause : nil,
        include_post_type_of,
        @permit_adjacent_sponsors ? true : false,
        include_post_type_of ? valid_paused_organization_ids : [],
        ApplicationConfig["SKIP_SURVEY_COMPLETION_FILTERING"] == "yes",
      ]
    end

    def normalize_optional_int(val)
      return if val.blank?
      return val if val.is_a?(Integer)
      return val.to_i if val.instance_of?(String) && val.match?(/\A[1-9]\d*\z/)

      :invalid
    end

    def normalize_tag_names(tags)
      return [] if tags.blank?
      return unless tags.is_a?(Array)

      tags.map do |tag|
        case tag
        when String then tag
        when Symbol then tag.to_s
        when ActsAsTaggableOn::Tag then tag.name
        else return nil
        end
      end
    end

    def normalize_string_list(list)
      return [] if list.blank?
      return unless list.is_a?(Array)

      list.map do |item|
        case item
        when String then item
        when Symbol then item.to_s
        else return nil
        end
      end
    end

    def verified_broadcast_event_ids
      return [] unless @area.in?(%w[feed_first post_fixed_bottom])

      Event.active_broadcast_events.each_with_object([]) do |active_event, ids|
        if active_event.global_broadcast? || (active_event.tagged_broadcast? && event_matches_tags?(active_event))
          ids << active_event.id
        end
      end
    end

    def apply_event_broadcast_overrides!
      verified_event_ids = verified_broadcast_event_ids
      if verified_event_ids.any?
        @filtered_billboards = @filtered_billboards.where(event_id: verified_event_ids)
        return
      end

      # For untouched configurations OR silent areas, strip any billboards intrinsically attached
      # to Events so they don't organically leak across default displays!
      @filtered_billboards = @filtered_billboards.where(event_id: nil)
    end

    def event_matches_tags?(event)
      event_tags = event.tags_array || []
      return false if event_tags.empty?

      (@article_tags & event_tags).any? || (@user_tags.to_a & event_tags).any?
    end

    def approved_and_published_ads
      @filtered_billboards.approved_and_published
    end

    def valid_paused_organization_ids
      paused_org_ids = Organizations::TrackPromotionalBillboardImpressionsWorker.paused_organization_ids
      return [] if paused_org_ids.blank?

      Array(paused_org_ids).filter_map(&:to_i)
    end

    def exclude_paused_promotional_billboards
      valid_paused_ids = valid_paused_organization_ids
      return @filtered_billboards if valid_paused_ids.empty?

      # Exclude billboards from paused organizations, but include those with no organization
      # Use a single WHERE clause - this pattern matches user_targeting_ads for consistency
      @filtered_billboards.where("organization_id IS NULL OR organization_id NOT IN (?)", valid_paused_ids)
    end

    def placement_area_ads
      @filtered_billboards.where(placement_area: @area)
    end

    def browser_context_ads
      context = ForemNative.classify_billboard_browser_context(@user_agent)
      if context
        return @filtered_billboards if context == :unknown

        return @filtered_billboards.where(browser_context: [:all_browsers, context])
      end

      case @user_agent
      when /DEV-Native-ios|DEV-Native-android|ForemWebView/
        @filtered_billboards.where(browser_context: %i[all_browsers mobile_in_app])
      when /Mobile|iPhone|Android/
        @filtered_billboards.where(browser_context: %i[all_browsers mobile_web])
      when /Windows|Macintosh|Mac OS X|Linux/
        @filtered_billboards.where(browser_context: %i[all_browsers desktop])
      else
        @filtered_billboards
      end
    end

    def page_ads
      @filtered_billboards.where(page_id: @page_id)
    end

    def tagged_or_untagged_ads(tags)
      if (tag_names = normalize_tag_names(tags))
        sql = ForemNative.build_billboard_tag_clause_sql(
          tag_names,
          true,
          ENV["OPTIMIZED_TAGGABLE_QUERY"] == "true",
        )
        return @filtered_billboards.where(Arel.sql(sql)) if sql
      end

      tagged_ads(tags).or(untagged_ads)
    end

    def tagged_ads(tag_type)
      @filtered_billboards.cached_tagged_with_any(tag_type)
    end

    def untagged_ads
      @filtered_billboards.where(cached_tag_list: "")
    end

    def unexcluded_article_ads
      @filtered_billboards.where(
        "exclude_article_ids IS NULL OR cardinality(exclude_article_ids) = 0 OR NOT (:id = ANY(exclude_article_ids))",
        id: @article_id,
      )
    end

    def included_subforem_ads
      sql = "include_subforem_ids IS NULL OR cardinality(include_subforem_ids) = 0 " \
            "OR :subforem_id = ANY(include_subforem_ids)"
      @filtered_billboards.where(
        sql,
        subforem_id: @subforem_id,
      )
    end

    def authenticated_ads(display_auth_audience)
      @filtered_billboards.where(display_to: display_auth_audience)
    end

    def cookies_allowed_ads
      @filtered_billboards.where(requires_cookies: false)
    end

    # A fully cached placement area serves the same response to everyone in a location, so it
    # can only offer billboards whose eligibility doesn't depend on who is asking or which
    # article or page they're on. Requiring cookies is fine: cookies_allowed is part of the URL.
    def request_independent_ads
      @filtered_billboards
        .where(cached_tag_list: [nil, ""], audience_segment_id: nil, page_id: nil)
        .where(exclude_survey_completions: false, browser_context: :all_browsers)
        .where("exclude_article_ids IS NULL OR cardinality(exclude_article_ids) = 0")
        .where("target_role_names IS NULL OR cardinality(target_role_names) = 0")
        .where("exclude_role_names IS NULL OR cardinality(exclude_role_names) = 0")
    end

    def user_targeting_ads
      if @user_id
        @filtered_billboards.where(
          "audience_segment_id IS NULL OR audience_segment_id IN (?)",
          SegmentedUser.where(user_id: @user_id).select(:audience_segment_id),
        )
      else
        @filtered_billboards.where(audience_segment_id: nil)
      end
    end

    def role_filtered_ads
      if @role_names.present?
        if (role_strs = normalize_string_list(@role_names)) &&
            (sql = ForemNative.build_billboard_role_filter_sql(role_strs))
          return @filtered_billboards.where(Arel.sql(sql))
        end

        @filtered_billboards.where(
          "(target_role_names IS NULL OR cardinality(target_role_names) = 0 " \
          "OR target_role_names && ARRAY[:role_names]::varchar[]) " \
          "AND (exclude_role_names IS NULL OR cardinality(exclude_role_names) = 0 " \
          "OR NOT exclude_role_names && ARRAY[:role_names]::varchar[])",
          role_names: @role_names,
        )
      else
        @filtered_billboards.where("target_role_names IS NULL OR cardinality(target_role_names) = 0")
      end
    end

    def location_targeted_ads
      geo_query = "target_geolocations IS NULL OR cardinality(target_geolocations) = 0" # Empty array
      if (clause = @location&.to_sql_query_clause)
        geo_query = "#{geo_query} OR (#{clause})"
      end

      @filtered_billboards.where(geo_query)
    end

    def type_of_ads
      types_matching = []

      # Always match in-house-type ads
      types_matching << :in_house

      # If the author or current_user has opted out of seeing adjacent sponsors, do not show them
      if @permit_adjacent_sponsors
        types_matching << :external
      end

      standard = @filtered_billboards.where(type_of: Billboard.type_ofs.slice(*types_matching).values)
      return standard if @organization_id.blank?

      # If this is an organization article and community-type ads exist, show only them. The
      # existence check is an uncorrelated NOT EXISTS (evaluated once by Postgres) inside the
      # same query, rather than a separate SELECT 1 round-trip on every organization article.
      community = @filtered_billboards.where(type_of: Billboard.type_ofs[:community],
                                             organization_id: @organization_id)
      community.or(standard.where(community.arel.exists.not))
    end

    def survey_completion_filtered_ads
      return @filtered_billboards if @user_id.blank?

      @filtered_billboards.where(
        "exclude_survey_completions = FALSE OR NOT EXISTS (" \
        "SELECT 1 FROM survey_completions " \
        "WHERE survey_completions.user_id = :user_id " \
        "AND survey_completions.survey_id = ANY(display_ads.exclude_survey_ids))",
        user_id: @user_id.respond_to?(:id) ? @user_id.id : @user_id,
      )
    end
  end
end
