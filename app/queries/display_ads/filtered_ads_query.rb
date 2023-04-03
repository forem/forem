module DisplayAds
  class FilteredAdsQuery
    def self.call(...)
      new(...).call
    end

    def initialize(area:, user_signed_in:, organization_id: nil, article_tags: [],
                   permit_adjacent_sponsors: true, article_id: nil, display_ads: DisplayAd)
      @filtered_display_ads = display_ads.includes([:organization])
      @area = area
      @user_signed_in = user_signed_in
      @organization_id = organization_id
      @article_tags = article_tags
      @article_id = article_id
      @permit_adjacent_sponsors = permit_adjacent_sponsors
    end

    def call
      @filtered_display_ads = approved_and_published_ads
      @filtered_display_ads = placement_area_ads

      if @article_tags.any?
        @filtered_display_ads = tagged_post_comment_ads
      end

      if @article_tags.blank?
        @filtered_display_ads = untagged_post_comment_ads
      end

      if @article_id.present?
        @filtered_display_ads = unexcluded_article_ads
      end

      @filtered_display_ads = if @user_signed_in
                                authenticated_ads(%w[all logged_in])
                              else
                                authenticated_ads(%w[all logged_out])
                              end

      # type_of filter needs to be applied as near to the end as possible
      # as it checks if any type-matching ads exist (this will apply all/any
      # filters applied up to this point, thus near the end is best)
      @filtered_display_ads = type_of_ads

      @filtered_display_ads = @filtered_display_ads.order(success_rate: :desc)
    end

    private

    def approved_and_published_ads
      @filtered_display_ads.approved_and_published
    end

    def placement_area_ads
      @filtered_display_ads.where(placement_area: @area)
    end

    def tagged_post_comment_ads
      display_ads_with_targeted_article_tags = @filtered_display_ads.cached_tagged_with_any(@article_tags)
      untagged_post_comment_ads.or(display_ads_with_targeted_article_tags)
    end

    def untagged_post_comment_ads
      @filtered_display_ads.where(cached_tag_list: "")
    end

    def unexcluded_article_ads
      @filtered_display_ads.where("NOT (:id = ANY(exclude_article_ids))", id: @article_id)
    end

    def authenticated_ads(display_auth_audience)
      @filtered_display_ads.where(display_to: display_auth_audience)
    end

    def type_of_ads
      # If this is an organization article and community-type ads exist, show them
      if @organization_id.present?
        community = @filtered_display_ads.where(type_of: DisplayAd.type_ofs[:community],
                                                organization_id: @organization_id)
        return community if community.any?
      end

      types_matching = []

      # Always match in-house-type ads
      types_matching << :in_house

      # If the article is an organization's article (non-nil organization_id),
      # or if the current_user has opted-out of sponsors,
      # then do not show external ads
      if @organization_id.blank? && @permit_adjacent_sponsors
        types_matching << :external
      end

      @filtered_display_ads.where(type_of: DisplayAd.type_ofs.slice(*types_matching).values)
    end
  end
end
